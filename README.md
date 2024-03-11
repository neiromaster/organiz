# Bash File Organizer

This Bash script organizes files from a source directory to a destination directory based on certain conditions. It also includes checks for the existence of a configuration file and handles the total size of the destination directory.

## Usage

To use this script, simply run it in your terminal:

```bash
./organiz.sh
```

## Configuration

The program requires a config to function. The config can be located next to the executable script and be named `config.conf`. If the config is not found next to the script, `~/.config.conf` will be used, and if it's not present, `~/.config/organiz/config.conf` will be used. If the config is not found, an error message will be displayed, and the script execution will be halted.

The configuration file can include several sections, each defining a separate task.

Each section can contain the following parameters for the task:
| Parameter | Description | Example |
|-----------|-------------|---------|
| `source_path` | Path to the source directory | `/path/to/source` |
| `store_path` | Path to the directory for storing anime | `/path/to/store` |
| `destination_path` | Path to the target directory | `/path/to/destination` |
| `file_filter` | Regular expression for selecting anime files | `.*\.(mkv\|mp4\|avi\|mov)` |
| `target_size` | Target size of the target directory (in bytes) | `20971520` |
| `max_files` | Maximum number of anime files in the target directory | `100` |

## License

This project is licensed under the MIT License - see the LICENSE file for details.
