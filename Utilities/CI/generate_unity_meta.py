import os, uuid

def generate_meta(target_path, is_dir, is_cs):
    meta_path = target_path + '.meta'

    # Skip if a .meta file already exists
    if os.path.exists(meta_path):
        return

    guid = uuid.uuid4().hex
    content = f"fileFormatVersion: 2\nguid: {guid}\n"

    if is_dir:
        content += "folderAsset: yes\nDefaultImporter:\n  externalObjects: {}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n"
    elif is_cs:
        content += "MonoImporter:\n  externalObjects: {}\n  serializedVersion: 2\n  iconMap: {}\n  executionOrder: 0\n"
    else:
        content += "DefaultImporter:\n  externalObjects: {}\n  userData: \n  assetBundleName: \n  assetBundleVariant: \n"

    with open(meta_path, 'w', encoding='utf-8') as f:
        f.write(content)

package_root = 'UnityPackage'

for root, dirs, files in os.walk(package_root):
    for dir_name in dirs:
        if dir_name.startswith('.'): continue
        target = os.path.join(root, dir_name)
        generate_meta(target, is_dir=True, is_cs=False)

    for file_name in files:
        if file_name.endswith('.meta') or file_name.startswith('.'): continue
        target = os.path.join(root, file_name)
        generate_meta(target, is_dir=False, is_cs=file_name.endswith('.cs'))