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
    elif file_path.suffix == '.so':
        # Safely target Android native plugins, strictly assigning ARM64 and Preload.
        # The preload makes sure that when the app looks for CSP it finds the lib in memory already loaded at startup.
        # Without the preload, a dll not found error could arise if not resolved some other way via code.
        body = ("PluginImporter:\n"
                "  externalObjects: {}\n"
                "  serializedVersion: 2\n"
                "  iconMap: {}\n"
                "  executionOrder: 0\n"
                "  defineConstraints: []\n"
                "  isPreloaded: 1\n"
                "  isOverridable: 0\n"
                "  isExplicitlyReferenced: 0\n"
                "  validateReferences: 1\n"
                "  platformData:\n"
                "  - first:\n"
                "      Any: \n"
                "    second:\n"
                "      enabled: 0\n"
                "      settings:\n"
                "        Exclude Editor: 1\n"
                "        Exclude Linux64: 1\n"
                "        Exclude macOS: 1\n"
                "        Exclude Win: 1\n"
                "        Exclude Win64: 1\n"
                "  - first:\n"
                "      Android: Android\n"
                "    second:\n"
                "      enabled: 1\n"
                "      settings:\n"
                "        CPU: ARM64\n"
                "  userData: \n"
                "  assetBundleName: \n"
                "  assetBundleVariant: ")
    elif file_path.suffix == '.a' and 'visionOS' in file_path.parts:
        # Target visionOS static libraries specifically. Static libraries don't need preloading like Android .so files.
        body = ("PluginImporter:\n"
                "  externalObjects: {}\n"
                "  serializedVersion: 2\n"
                "  iconMap: {}\n"
                "  executionOrder: 0\n"
                "  defineConstraints: []\n"
                "  isPreloaded: 0\n"
                "  isOverridable: 0\n"
                "  isExplicitlyReferenced: 0\n"
                "  validateReferences: 1\n"
                "  platformData:\n"
                "  - first:\n"
                "      Any: \n"
                "    second:\n"
                "      enabled: 0\n"
                "      settings:\n"
                "        Exclude Editor: 1\n"
                "        Exclude Linux64: 1\n"
                "        Exclude macOS: 1\n"
                "        Exclude Win: 1\n"
                "        Exclude Win64: 1\n"
                "  - first:\n"
                "      visionOS: visionOS\n"
                "    second:\n"
                "      enabled: 1\n"
                "      settings:\n"
                "        CPU: ARM64\n"
                "  userData: \n"
                "  assetBundleName: \n"
                "  assetBundleVariant: ")
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