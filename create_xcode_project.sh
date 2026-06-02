#!/bin/bash
# ============================================================
# Scholar - Xcode 项目生成脚本
# 在 Mac 上运行此脚本，自动生成标准 .xcodeproj 项目
# 用法: chmod +x create_xcode_project.sh && ./create_xcode_project.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_NAME="Scholar"
APP_DIR="$SCRIPT_DIR/$PROJECT_NAME"
XCODEPROJ_DIR="$SCRIPT_DIR/${PROJECT_NAME}.xcodeproj"

echo "🔧 正在生成 Xcode 项目..."

# 创建 Info.plist
cat > "$APP_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSRemindersUsageDescription</key>
    <string>Scholar 需要访问提醒事项，以便把项目任务同步到 Apple 提醒事项。</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Scholar 需要控制提醒事项，以便把事务任务同步为提醒事项中的缩进子项。</string>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "✅ Info.plist 已创建"

# 生成 PBX 文件
SCRIPT_DIR_ENV="$SCRIPT_DIR" APP_DIR_ENV="$APP_DIR" PROJECT_NAME_ENV="$PROJECT_NAME" python3 << 'PYTHON_SCRIPT'
import os
import uuid
import plistlib

script_dir = os.environ["SCRIPT_DIR_ENV"]
app_dir = os.environ["APP_DIR_ENV"]
project_name = os.environ["PROJECT_NAME_ENV"]

def make_uuid():
    return uuid.uuid4().hex[:24].upper()

# Collect swift files
swift_files = []
for root, dirs, files in os.walk(app_dir):
    for f in sorted(files):
        if f.endswith('.swift'):
            swift_files.append(os.path.join(root, f))

resource_files = []
for root, dirs, files in os.walk(app_dir):
    for dirname in sorted(dirs):
        full_dir = os.path.join(root, dirname)
        if dirname.endswith(".xcassets"):
            resource_files.append(full_dir)
    dirs[:] = [dirname for dirname in dirs if not dirname.endswith(".xcassets")]
    for f in sorted(files):
        full_file = os.path.join(root, f)
        if "/Resources/" in full_file.replace("\\\\", "/"):
            resource_files.append(full_file)

# Create IDs
project_object_id = make_uuid()
main_group_id = make_uuid()
sources_group_id = make_uuid()
resources_group_id = make_uuid()
products_group_id = make_uuid()
frameworks_group_id = make_uuid()
build_config_list_id = make_uuid()
debug_config_id = make_uuid()
release_config_id = make_uuid()
native_target_id = make_uuid()
sources_build_phase_id = make_uuid()
resources_build_phase_id = make_uuid()
frameworks_build_phase_id = make_uuid()
product_ref_id = make_uuid()
info_plist_id = make_uuid()

# File references
file_refs = {}
build_files = {}
resource_file_refs = {}
resource_build_files = {}

for f in swift_files:
    fid = make_uuid()
    bf_id = make_uuid()
    rel_path = os.path.relpath(f, script_dir)
    file_refs[f] = fid
    build_files[f] = bf_id

for f in resource_files:
    fid = make_uuid()
    bf_id = make_uuid()
    resource_file_refs[f] = fid
    resource_build_files[f] = bf_id

# Info.plist
info_plist_rel = os.path.relpath(os.path.join(app_dir, "Info.plist"), script_dir)

# Build the pbxproj dictionary
pbx = {
    'archiveVersion': '1',
    'classes': {},
    'objectVersion': '56',
    'objects': {},
    'rootObject': project_object_id,
}

objects = pbx['objects']

# PBXProject
objects[project_object_id] = {
    'isa': 'PBXProject',
    'attributes': {
        'BuildIndependentTargetsInParallel': 1,
        'LastSwiftUpdateCheck': '1540',
        'LastUpgradeCheck': '1540',
        'TargetAttributes': {
            native_target_id: {
                'CreatedOnToolsVersion': '15.4',
            }
        }
    },
    'buildConfigurationList': build_config_list_id,
    'compatibilityVersion': 'Xcode 14.0',
    'developmentRegion': 'zh-Hans',
    'hasScannedForEncodings': 0,
    'knownRegions': ['zh-Hans', 'en', 'Base'],
    'mainGroup': main_group_id,
    'productRefGroup': products_group_id,
    'projectDirPath': '',
    'projectRoot': '',
    'targets': [native_target_id],
}

# PBXGroup - Main
children_main = [sources_group_id, resources_group_id, frameworks_group_id, products_group_id]
objects[main_group_id] = {
    'isa': 'PBXGroup',
    'children': children_main,
    'sourceTree': '<group>',
}

# PBXGroup - Sources
children_sources = []
for f in swift_files:
    children_sources.append(file_refs[f])
objects[sources_group_id] = {
    'isa': 'PBXGroup',
    'children': children_sources,
    'sourceTree': '<group>',
    'name': 'Sources',
}

# PBXGroup - Resources
children_resources = [info_plist_id]
for f in resource_files:
    children_resources.append(resource_file_refs[f])
objects[resources_group_id] = {
    'isa': 'PBXGroup',
    'children': children_resources,
    'sourceTree': '<group>',
    'name': 'Resources',
}

# PBXGroup - Frameworks
objects[frameworks_group_id] = {
    'isa': 'PBXGroup',
    'children': [],
    'sourceTree': '<group>',
    'name': 'Frameworks',
}

# PBXGroup - Products
objects[products_group_id] = {
    'isa': 'PBXGroup',
    'children': [product_ref_id],
    'sourceTree': '<group>',
    'name': 'Products',
}

# PBXFileReference for each swift file
for f in swift_files:
    rel_path = os.path.relpath(f, script_dir)
    objects[file_refs[f]] = {
        'isa': 'PBXFileReference',
        'lastKnownFileType': 'sourcecode.swift',
        'path': rel_path,
        'sourceTree': 'SOURCE_ROOT',
    }

# PBXFileReference for each resource
for f in resource_files:
    rel_path = os.path.relpath(f, script_dir)
    last_known_type = 'folder.assetcatalog' if f.endswith('.xcassets') else 'text'
    objects[resource_file_refs[f]] = {
        'isa': 'PBXFileReference',
        'lastKnownFileType': last_known_type,
        'path': rel_path,
        'sourceTree': 'SOURCE_ROOT',
    }

# PBXFileReference for Info.plist
objects[info_plist_id] = {
    'isa': 'PBXFileReference',
    'lastKnownFileType': 'text.plist.xml',
    'path': info_plist_rel,
    'sourceTree': 'SOURCE_ROOT',
}

# PBXFileReference for product
objects[product_ref_id] = {
    'isa': 'PBXFileReference',
    'explicitFileType': 'wrapper.application',
    'includeInIndex': 0,
    'path': f'{project_name}.app',
    'sourceTree': 'BUILT_PRODUCTS_DIR',
}

# PBXBuildFile for each swift file
for f in swift_files:
    objects[build_files[f]] = {
        'isa': 'PBXBuildFile',
        'fileRef': file_refs[f],
    }

for f in resource_files:
    objects[resource_build_files[f]] = {
        'isa': 'PBXBuildFile',
        'fileRef': resource_file_refs[f],
    }

# PBXNativeTarget
objects[native_target_id] = {
    'isa': 'PBXNativeTarget',
    'buildConfigurationList': build_config_list_id,
    'buildPhases': [sources_build_phase_id, resources_build_phase_id, frameworks_build_phase_id],
    'buildRules': [],
    'dependencies': [],
    'name': project_name,
    'productName': project_name,
    'productReference': product_ref_id,
    'productType': 'com.apple.product-type.application',
}

# PBXSourcesBuildPhase
objects[sources_build_phase_id] = {
    'isa': 'PBXSourcesBuildPhase',
    'buildActionMask': 2147483647,
    'files': [build_files[f] for f in swift_files],
    'runOnlyForDeploymentPostprocessing': 0,
}

# PBXResourcesBuildPhase
objects[resources_build_phase_id] = {
    'isa': 'PBXResourcesBuildPhase',
    'buildActionMask': 2147483647,
    'files': [resource_build_files[f] for f in resource_files],
    'runOnlyForDeploymentPostprocessing': 0,
}

# PBXFrameworksBuildPhase
objects[frameworks_build_phase_id] = {
    'isa': 'PBXFrameworksBuildPhase',
    'buildActionMask': 2147483647,
    'files': [],
    'runOnlyForDeploymentPostprocessing': 0,
}

# XCBuildConfiguration - Debug
objects[debug_config_id] = {
    'isa': 'XCBuildConfiguration',
    'buildSettings': {
        'ALWAYS_SEARCH_USER_PATHS': 'NO',
        'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
        'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS': 'YES',
        'CLANG_ANALYZER_NONNULL': 'YES',
        'CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION': 'YES_AGGRESSIVE',
        'CLANG_CXX_LANGUAGE_STANDARD': 'gnu++20',
        'CLANG_ENABLE_MODULES': 'YES',
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'CLANG_ENABLE_OBJC_WEAK': 'YES',
        'CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING': 'YES',
        'CLANG_WARN_BOOL_CONVERSION': 'YES',
        'CLANG_WARN_COMMA': 'YES',
        'CLANG_WARN_CONSTANT_CONVERSION': 'YES',
        'CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS': 'YES',
        'CLANG_WARN_DIRECT_OBJC_ISA_USAGE': 'YES_ERROR',
        'CLANG_WARN_DOCUMENTATION_COMMENTS': 'YES',
        'CLANG_WARN_EMPTY_BODY': 'YES',
        'CLANG_WARN_ENUM_CONVERSION': 'YES',
        'CLANG_WARN_INFINITE_RECURSION': 'YES',
        'CLANG_WARN_INT_CONVERSION': 'YES',
        'CLANG_WARN_NON_LITERAL_NULL_CONVERSION': 'YES',
        'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF': 'YES',
        'CLANG_WARN_OBJC_LITERAL_CONVERSION': 'YES',
        'CLANG_WARN_OBJC_ROOT_CLASS': 'YES_ERROR',
        'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER': 'YES',
        'CLANG_WARN_RANGE_LOOP_ANALYSIS': 'YES',
        'CLANG_WARN_STRICT_PROTOTYPES': 'YES',
        'CLANG_WARN_SUSPICIOUS_MOVE': 'YES',
        'CLANG_WARN_UNGUARDED_AVAILABILITY': 'YES_AGGRESSIVE',
        'CLANG_WARN_UNREACHABLE_CODE': 'YES',
        'CLANG_WARN__DUPLICATE_METHOD_MATCH': 'YES',
        'COPY_PHASE_STRIP': 'NO',
        'DEBUG_INFORMATION_FORMAT': 'dwarf',
        'ENABLE_STRICT_OBJC_MSGSEND': 'YES',
        'ENABLE_TESTABILITY': 'YES',
        'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
        'GCC_C_LANGUAGE_STANDARD': 'gnu17',
        'GCC_DYNAMIC_NO_PIC': 'NO',
        'GCC_NO_COMMON_BLOCKS': 'YES',
        'GCC_OPTIMIZATION_LEVEL': '0',
        'GCC_PREPROCESSOR_DEFINITIONS': ['DEBUG=1', '$(inherited)'],
        'GCC_WARN_64_TO_32_BIT_CONVERSION': 'YES',
        'GCC_WARN_ABOUT_RETURN_TYPE': 'YES_ERROR',
        'GCC_WARN_UNDECLARED_SELECTOR': 'YES',
        'GCC_WARN_UNINITIALIZED_AUTOS': 'YES_AGGRESSIVE',
        'GCC_WARN_UNUSED_FUNCTION': 'YES',
        'GCC_WARN_UNUSED_VARIABLE': 'YES',
        'MACOSX_DEPLOYMENT_TARGET': '14.0',
        'INFOPLIST_FILE': f'{project_name}/Info.plist',
        'MTL_ENABLE_DEBUG_INFO': 'INCLUDE_SOURCE',
        'MTL_FAST_MATH': 'YES',
        'ONLY_ACTIVE_ARCH': 'YES',
        'PRODUCT_BUNDLE_IDENTIFIER': 'local.Scholar',
        'PRODUCT_BUNDLE_PACKAGE_TYPE': 'APPL',
        'PRODUCT_NAME': '$(TARGET_NAME)',
        'SDKROOT': 'macosx',
        'SWIFT_ACTIVE_COMPILATION_CONDITIONS': 'DEBUG $(inherited)',
        'SWIFT_OPTIMIZATION_LEVEL': '-Onone',
        'SWIFT_VERSION': '5.0',
    },
    'name': 'Debug',
}

# XCBuildConfiguration - Release
objects[release_config_id] = {
    'isa': 'XCBuildConfiguration',
    'buildSettings': {
        'ALWAYS_SEARCH_USER_PATHS': 'NO',
        'ASSETCATALOG_COMPILER_APPICON_NAME': 'AppIcon',
        'ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS': 'YES',
        'CLANG_ANALYZER_NONNULL': 'YES',
        'CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION': 'YES_AGGRESSIVE',
        'CLANG_CXX_LANGUAGE_STANDARD': 'gnu++20',
        'CLANG_ENABLE_MODULES': 'YES',
        'CLANG_ENABLE_OBJC_ARC': 'YES',
        'CLANG_ENABLE_OBJC_WEAK': 'YES',
        'CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING': 'YES',
        'CLANG_WARN_BOOL_CONVERSION': 'YES',
        'CLANG_WARN_COMMA': 'YES',
        'CLANG_WARN_CONSTANT_CONVERSION': 'YES',
        'CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS': 'YES',
        'CLANG_WARN_DIRECT_OBJC_ISA_USAGE': 'YES_ERROR',
        'CLANG_WARN_DOCUMENTATION_COMMENTS': 'YES',
        'CLANG_WARN_EMPTY_BODY': 'YES',
        'CLANG_WARN_ENUM_CONVERSION': 'YES',
        'CLANG_WARN_INFINITE_RECURSION': 'YES',
        'CLANG_WARN_INT_CONVERSION': 'YES',
        'CLANG_WARN_NON_LITERAL_NULL_CONVERSION': 'YES',
        'CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF': 'YES',
        'CLANG_WARN_OBJC_LITERAL_CONVERSION': 'YES',
        'CLANG_WARN_OBJC_ROOT_CLASS': 'YES_ERROR',
        'CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER': 'YES',
        'CLANG_WARN_RANGE_LOOP_ANALYSIS': 'YES',
        'CLANG_WARN_STRICT_PROTOTYPES': 'YES',
        'CLANG_WARN_SUSPICIOUS_MOVE': 'YES',
        'CLANG_WARN_UNGUARDED_AVAILABILITY': 'YES_AGGRESSIVE',
        'CLANG_WARN_UNREACHABLE_CODE': 'YES',
        'CLANG_WARN__DUPLICATE_METHOD_MATCH': 'YES',
        'COPY_PHASE_STRIP': 'NO',
        'DEBUG_INFORMATION_FORMAT': 'dwarf-with-dsym',
        'ENABLE_NS_ASSERTIONS': 'NO',
        'ENABLE_STRICT_OBJC_MSGSEND': 'YES',
        'ENABLE_USER_SCRIPT_SANDBOXING': 'YES',
        'GCC_C_LANGUAGE_STANDARD': 'gnu17',
        'GCC_NO_COMMON_BLOCKS': 'YES',
        'GCC_WARN_64_TO_32_BIT_CONVERSION': 'YES',
        'GCC_WARN_ABOUT_RETURN_TYPE': 'YES_ERROR',
        'GCC_WARN_UNDECLARED_SELECTOR': 'YES',
        'GCC_WARN_UNINITIALIZED_AUTOS': 'YES_AGGRESSIVE',
        'GCC_WARN_UNUSED_FUNCTION': 'YES',
        'GCC_WARN_UNUSED_VARIABLE': 'YES',
        'MACOSX_DEPLOYMENT_TARGET': '14.0',
        'INFOPLIST_FILE': f'{project_name}/Info.plist',
        'MTL_ENABLE_DEBUG_INFO': 'NO',
        'MTL_FAST_MATH': 'YES',
        'PRODUCT_BUNDLE_IDENTIFIER': 'local.Scholar',
        'PRODUCT_BUNDLE_PACKAGE_TYPE': 'APPL',
        'PRODUCT_NAME': '$(TARGET_NAME)',
        'SDKROOT': 'macosx',
        'SWIFT_COMPILATION_MODE': 'wholemodule',
        'SWIFT_VERSION': '5.0',
    },
    'name': 'Release',
}

# XCConfigurationList
objects[build_config_list_id] = {
    'isa': 'XCConfigurationList',
    'buildConfigurations': [debug_config_id, release_config_id],
    'defaultConfigurationIsVisible': 0,
    'defaultConfigurationName': 'Release',
}

# Write pbxproj
pbxproj_path = os.path.join(script_dir, f'{project_name}.xcodeproj', 'project.pbxproj')
os.makedirs(os.path.dirname(pbxproj_path), exist_ok=True)

with open(pbxproj_path, 'wb') as f:
    plistlib.dump(pbx, f, sort_keys=False)

# Write shared scheme
scheme_dir = os.path.join(script_dir, f'{project_name}.xcodeproj', 'xcshareddata', 'xcschemes')
os.makedirs(scheme_dir, exist_ok=True)

scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1540"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{native_target_id}"
               BuildableName = "{project_name}.app"
               BlueprintName = "{project_name}"
               ReferencedContainer = "container:{project_name}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{native_target_id}"
            BuildableName = "{project_name}.app"
            BlueprintName = "{project_name}"
            ReferencedContainer = "container:{project_name}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
'''

with open(os.path.join(scheme_dir, f'{project_name}.xcscheme'), 'w') as f:
    f.write(scheme)

print(f"✅ Xcode 项目已生成: {pbxproj_path}")
print(f"✅ Scheme 已生成: {scheme_dir}/{project_name}.xcscheme")
PYTHON_SCRIPT

echo ""
echo "🎉 完成！现在可以用 Xcode 打开项目："
echo ""
echo "   cd $SCRIPT_DIR"
echo "   open ${PROJECT_NAME}.xcodeproj"
echo ""
echo "   然后按 Cmd+R 运行"
