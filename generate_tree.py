import os

def generate_tree(root_dir, exclude_dirs, output_file):
    with open(output_file, 'w', encoding='utf-8') as f:
        for root, dirs, files in os.walk(root_dir):
            # Prune excluded directories in-place so os.walk skips them entirely
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            # Calculate depth for indentation
            level = root.replace(root_dir, '').count(os.sep)
            indent = ' ' * 4 * (level)
            
            # Write the current directory name
            folder_name = os.path.basename(root) if os.path.basename(root) else root
            f.write(f'{indent}{folder_name}/\n')
            
            # Write the files in the directory
            sub_indent = ' ' * 4 * (level + 1)
            for file in files:
                f.write(f'{sub_indent}{file}\n')

if __name__ == "__main__":
    # CONFIGURATION
    TARGET_PATH = r"D:\esp\mqtt_demo"
    EXCLUDES = {"managed_components", "build", ".vscode", "bootloader", "__pycache__", ".git"}
    OUTPUT_NAME = "structure.txt"

    print(f"Generating structure for: {TARGET_PATH}...")
    generate_tree(TARGET_PATH, EXCLUDES, OUTPUT_NAME)
    print(f"Done! Created {OUTPUT_NAME}")