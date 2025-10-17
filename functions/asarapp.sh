# filename: -f <filename>.app and extracts <filename>.app/Contents/Resources/app.asar to <filename>_asar
# input: -i <filename>_asar and packs it back to <filename>.app/Contents/Resources/app.asar
# usage: asarapp -f <filename>.app or -i <filename>_asar
function asarapp() {
    if [ "$1" = "-f" ]; then
        if [ -z "$2" ]; then
            echo "Usage: asarapp -f <filename>.app"
            return 1
        fi
        filename="$2"
        app_dir="${filename%.*}.app/Contents/Resources"
        asar_file="$app_dir/app.asar"
        if [ ! -f "$asar_file" ]; then
            echo "Error: $asar_file not found."
            return 1
        fi
        mkdir -p "${filename%.*}_asar"
        bunx asar extract "$asar_file" "${filename%.*}_asar"
    elif [ "$1" = "-i" ]; then
        if [ -z "$2" ]; then
            echo "Usage: asarapp -i <filename>_asar"
            return 1
        fi
        filename="$2"
        app_dir="${filename%_asar}.app/Contents/Resources"
        asar_file="$app_dir/app.asar"
        if [ ! -d "$filename" ]; then
            echo "Error: $filename not found."
            return 1
        fi
        # Improvement #4: Verify app directory exists before packing
        if [ ! -d "$app_dir" ]; then
            echo "Error: Application directory $app_dir not found."
            return 1
        fi
        # Improvement #2: Create backup with timestamp before overwriting
        if [ -f "$asar_file" ]; then
            timestamp=$(date +"%Y%m%d%H%M%S")
            backup_file="$app_dir/app_backup_${timestamp}.asar"
            echo "Creating backup of original ASAR file to $backup_file"
            cp "$asar_file" "$backup_file"
        fi
        bunx asar pack "$filename" "$asar_file"
    else
        echo "Usage: asarapp -f <filename>.app or -i <filename>_asar"
    fi
    if [ $? -eq 0 ]; then
        echo "Operation completed successfully."
    else
        echo "Error: Operation failed."
    fi
}