import tensorflow as tf
from tensorflow.keras import layers, models
import json

# Dataset paths
train_dir = r"C:\Users\shlok\Downloads\food-101\train"
val_dir = r"C:\Users\shlok\Downloads\food-101\validation"

img_size = (128, 128)
batch_size = 32

# Load datasets
train_data = tf.keras.preprocessing.image_dataset_from_directory(
    train_dir,
    image_size=img_size,
    batch_size=batch_size
)

val_data = tf.keras.preprocessing.image_dataset_from_directory(
    val_dir,
    image_size=img_size,
    batch_size=batch_size
)

# Save class names
class_names = train_data.class_names

with open("class_names.json", "w") as f:
    json.dump(class_names, f)

# MobileNetV2 base model
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(128, 128, 3),
    include_top=False,
    weights="imagenet"
)

base_model.trainable = False

# Build model
model = models.Sequential([
    layers.Rescaling(1.0 / 255),
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dense(128, activation="relu"),
    layers.Dense(len(class_names), activation="softmax")
])

# Compile
model.compile(
    optimizer="adam",
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)

# Train
history = model.fit(
    train_data,
    validation_data=val_data,
    epochs=10
)

# Save model
model.save("food_model.h5")

print("Model saved successfully!")
