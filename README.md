# Bash File Organizer

This Bash script organizes files by moving them from a source directory to a destination directory based on specified criteria. It uses a configuration file to manage different tasks and also controls the total size of the destination directory.

## Usage

To use the script, execute it from your terminal:

```bash
./organiz.sh
```

## Configuration

The script requires a configuration file named `config.conf` to operate. It searches for this file in the following order:
1. In the same directory as the script.
2. In the user's home directory (`~/.config.conf`).
3. In the user's config directory (`~/.config/organiz/config.conf`).

If the configuration file is not found in any of these locations, the script will display an error and exit.

The configuration file can be divided into multiple sections, with each section representing a distinct task. Each task can be configured with the following parameters:

| Parameter | Description | Example |
|-----------|-------------|---------|
| `source_path` | The path to the source directory. | `/path/to/source` |
| `store_path` | The path to the intermediate storage directory. | `/path/to/store` |
| `backup_path` | The path for backing up the storage directory. | `/path/to/backup` |
| `destination_path` | The path to the final destination directory. | `/path/to/destination` |
| `file_filter` | A regular expression to filter files by name. | `.*\.(mkv\|mp4\|avi\|mov)` |
| `target_size` | The maximum size of the destination directory in bytes. | `20971520` |
| `max_files` | The maximum number of files per subdirectory in the destination. | `100` |

## License

This project is licensed under the MIT License - see the LICENSE file for details.
