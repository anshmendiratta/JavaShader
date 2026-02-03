import os
import glob

old_composite = input("rename composite: ")
new_composite = input("to composite: ")
directory = input("directory: ")

paths = glob.glob(f"{directory}/composite{old_composite}.**")  # Look for exact match.
extensions = [".vsh", ".fsh"]

for path in paths:
    if not os.path.isfile(path):
        print("cannot push directories")
        continue

    file_extension = os.path.splitext(path)
    if file_extension not in extensions:
        continue

    new_path = f"{directory}/composite{new_composite}{file_extension}"
    if os.path.is_file(new_path):
        print(f"replaced {new_path}")

    os.rename(path, new_path)
