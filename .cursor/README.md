# Welcome to the .cursor directory!

This file explains what the sub-directories in your `.cursor` directory do.
All these sub-directories were created by the [init.sh](https://github.com/erazemk/cursor/blob/main/init.sh) script, which you can find at [github.com/erazemk/cursor](https://github.com/erazemk/cursor).

If you accidentally messed up your `update.sh` script, you can reinitialize the configuration by manually running the initialization script:

```sh
curl -s https://raw.githubusercontent.com/erazemk/cursor/main/init.sh | sh
```

## Libraries

For Cursor to be able to give you good suggestions, it needs to index relevant files (i.e., libraries that contain definitions of the functions your code calls) and to do that most efficiently, the initialization script checks which libraries the project uses and caches them in the `.cursor/libraries` directory.

This directory should be excluded from Git (and it automatically is by the script).

## Rules

This directory contains rules that Cursor should use when writing code.
Rules can describe coding styles, which libraries to use (e.g., to always use the shared log library for logging) etc.

Some rules are included by the script (you can see which at [github.com/erazemk/cursor](https://github.com/erazemk/cursor)) and some can be added by you specifically for your project.
