import hashlib
from pathlib import Path

def get_guid(name_string):
    # Deterministic: same path = same GUID
    return hashlib.md5(name_string.encode('utf-8')).hexdigest()

def generate_meta(file_path: Path, package_root: Path, is_directory: bool):
    # Append .meta without stripping the original extension
    meta_path = file_path.parent / (file_path.name + '.meta')

    # Skip if a .meta file already exists
    if meta_path.exists():
        return


    # Everything is relative to the root (forced to forward slashes)
    rel_path_str = file_path.relative_to(package_root).as_posix()
    guid = get_guid(rel_path_str)

    if is_directory:
        body = ("folderAsset: yes\n"
                "DefaultImporter:\n"
                "  externalObjects: {}\n"
                "  userData: \n"
                "  assetBundleName: \n"
                "  assetBundleVariant: ")
    elif file_path.suffix == '.cs':
        body = ("MonoImporter:\n"
                "  externalObjects: {}\n"
                "  serializedVersion: 2\n"
                "  iconMap: {}\n"
                "  executionOrder: 0")
    else:
        body = ("DefaultImporter:\n"
                "  externalObjects: {}\n"
                "  userData: \n"
                "  assetBundleName: \n"
                "  assetBundleVariant: ")
    
    content = f"fileFormatVersion: 2\nguid: {guid}\n{body}\n"
    
    # Note: forcing newline format to make sure this persists across platforms
    with meta_path.open("w", encoding="utf-8", newline="\n") as f:
        f.write(content)


package_dir = Path('UnityPackage').resolve()

# Generate .meta for everything inside the root directory
for item in package_dir.rglob('*'):
    # Skip existing metas, hidden files, and the root itself
    if item.suffix == '.meta' or item.name.startswith('.'):
        continue

    is_dir = item.is_dir()
    generate_meta(item, package_dir, is_dir)