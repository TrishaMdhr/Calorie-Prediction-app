import json
import os
import sys

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.callbacks import EarlyStopping, ModelCheckpoint, ReduceLROnPlateau

TRAINING_DIR  = os.path.dirname(os.path.abspath(__file__))
ML_ROOT       = os.path.dirname(TRAINING_DIR)
ARTIFACTS_DIR = os.path.join(ML_ROOT, "artifacts")

train_dir = os.getenv("FOOD101_TRAIN_DIR", "")
val_dir   = os.getenv("FOOD101_VAL_DIR", "")

if not train_dir or not val_dir:
    print("ERROR: Set FOOD101_TRAIN_DIR and FOOD101_VAL_DIR environment variables.")
    sys.exit(1)

# ── Hyper-parameters ──────────────────────────────────────────────────────────
IMG_SIZE   = (224, 224)   # Fix #1: native resolution for pretrained backbones
BATCH_SIZE = 32

# ── Load datasets ─────────────────────────────────────────────────────────────
train_data = tf.keras.preprocessing.image_dataset_from_directory(
    train_dir,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="int",
    shuffle=True,
    seed=42,
)
val_data = tf.keras.preprocessing.image_dataset_from_directory(
    val_dir,
    image_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    label_mode="int",
    shuffle=False,
)

class_names = train_data.class_names
num_classes  = len(class_names)
print(f"Found {num_classes} food classes.")

os.makedirs(ARTIFACTS_DIR, exist_ok=True)
with open(os.path.join(ARTIFACTS_DIR, "class_names.json"), "w") as f:
    json.dump(class_names, f)

# ── Fix #4: Data augmentation ─────────────────────────────────────────────────
augmentation = models.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.15),
    layers.RandomZoom(0.15),
    layers.RandomContrast(0.15),
], name="augmentation")

autotune   = tf.data.AUTOTUNE
train_data = train_data.map(
    lambda x, y: (augmentation(x, training=True), y),
    num_parallel_calls=autotune,
).prefetch(autotune)
val_data = val_data.prefetch(autotune)

# ── Fix #2 & #3: EfficientNetV2S backbone with built-in preprocessing ─────────
# include_preprocessing=True means pixels should be raw [0, 255] float32.
# Do NOT add a Rescaling layer — that would double-normalise and break inference.
base_model = tf.keras.applications.EfficientNetV2S(
    input_shape=(*IMG_SIZE, 3),
    include_top=False,
    weights="imagenet",
    include_preprocessing=True,
)
base_model.trainable = False

inputs  = tf.keras.Input(shape=(*IMG_SIZE, 3))
x       = base_model(inputs, training=False)
x       = layers.GlobalAveragePooling2D()(x)
x       = layers.BatchNormalization()(x)
x       = layers.Dense(256, activation="relu")(x)
x       = layers.Dropout(0.4)(x)
outputs = layers.Dense(num_classes, activation="softmax")(x)

model = tf.keras.Model(inputs, outputs)

# ── Phase 1: Train head only ──────────────────────────────────────────────────
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-3),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

callbacks_phase1 = [
    EarlyStopping(monitor="val_accuracy", patience=5, restore_best_weights=True, mode="max"),
    ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=3, min_lr=1e-6, verbose=1),
    ModelCheckpoint(
        os.path.join(ARTIFACTS_DIR, "food_model_phase1.keras"),
        monitor="val_accuracy", save_best_only=True, mode="max", verbose=1,
    ),
]

print("\n=== Phase 1: Training classification head (backbone frozen) ===")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=15,
    callbacks=callbacks_phase1,
)

# ── Fix #5: Phase 2 — fine-tune last 60 layers (was 30) ──────────────────────
base_model.trainable = True
for layer in base_model.layers[:-60]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=5e-5),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

callbacks_phase2 = [
    EarlyStopping(monitor="val_accuracy", patience=7, restore_best_weights=True, mode="max"),
    ReduceLROnPlateau(monitor="val_loss", factor=0.3, patience=3, min_lr=1e-7, verbose=1),
    ModelCheckpoint(
        os.path.join(ARTIFACTS_DIR, "food_model.keras"),
        monitor="val_accuracy", save_best_only=True, mode="max", verbose=1,
    ),
]

print("\n=== Phase 2: Fine-tuning top 60 layers of EfficientNetV2S ===")
model.fit(
    train_data,
    validation_data=val_data,
    epochs=20,
    callbacks=callbacks_phase2,
)

print(f"\nDone! Best model saved to: {os.path.join(ARTIFACTS_DIR, 'food_model.keras')}")
print("Class names saved to:", os.path.join(ARTIFACTS_DIR, "class_names.json"))
