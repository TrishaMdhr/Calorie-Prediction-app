"""
Train the Food-101 CNN model. Run only when you need to rebuild food_model.keras.

Set dataset paths before running:
  $env:FOOD101_TRAIN_DIR = "C:\path\to\food-101\train"
  $env:FOOD101_VAL_DIR = "C:\path\to\food-101\validation"
  python ml/training/train_cnn.py
"""

import json
import os
import sys

import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.callbacks import EarlyStopping

TRAINING_DIR = os.path.dirname(os.path.abspath(__file__))
ML_ROOT = os.path.dirname(TRAINING_DIR)
ARTIFACTS_DIR = os.path.join(ML_ROOT, "artifacts")

train_dir = os.getenv("FOOD101_TRAIN_DIR", "")
val_dir = os.getenv("FOOD101_VAL_DIR", "")

if not train_dir or not val_dir:
    print("Set FOOD101_TRAIN_DIR and FOOD101_VAL_DIR environment variables.")
    sys.exit(1)

img_size = (128, 128)
batch_size = 32

train_data = tf.keras.preprocessing.image_dataset_from_directory(
    train_dir,
    image_size=img_size,
    batch_size=batch_size,
)
val_data = tf.keras.preprocessing.image_dataset_from_directory(
    val_dir,
    image_size=img_size,
    batch_size=batch_size,
)

class_names = train_data.class_names
os.makedirs(ARTIFACTS_DIR, exist_ok=True)

with open(os.path.join(ARTIFACTS_DIR, "class_names.json"), "w") as f:
    json.dump(class_names, f)

autotune = tf.data.AUTOTUNE
train_data = train_data.prefetch(buffer_size=autotune)
val_data = val_data.prefetch(buffer_size=autotune)

base_model = tf.keras.applications.MobileNetV2(
    input_shape=(128, 128, 3),
    include_top=False,
    weights="imagenet",
)
base_model.trainable = False

model = models.Sequential([
    layers.Rescaling(1.0 / 255),
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation="relu"),
    layers.Dropout(0.3),
    layers.Dense(len(class_names), activation="softmax"),
])

model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

early_stop = EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True)

model.fit(train_data, validation_data=val_data, epochs=10, callbacks=[early_stop])

base_model.trainable = True
for layer in base_model.layers[:-30]:
    layer.trainable = False

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-5),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"],
)

model.fit(train_data, validation_data=val_data, epochs=10, callbacks=[early_stop])

model_path = os.path.join(ARTIFACTS_DIR, "food_model.keras")
model.save(model_path)
print(f"Model saved to {model_path}")
