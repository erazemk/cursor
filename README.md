# Context-aware Cursor configuration

This repo contains a collection of Cursor rules that can be used in most Go-based repositories and a collection of utilities that make working with Cursor fairly painless, while still allowing it to index all the repositories it needs to write good code.

## Purpose

The primary purpose of this repo is to serve as a central hub for Cursor rules, so that the [`init.sh`](init.sh) script can clone them to individual repos, and to host the script itself, which automates a lot of the initial configuration required for Cursor (e.g. cloning libraries so that Cursor can index them).

After extensive playing around with Cursor, messing with all the settings and trying to get it to work well with my code, I have found that the most painless way to give it enough context is to clone all the repositories that it needs into a Git-ignored directory, which it can index.

This is needed because:

- Cursor doesn't index directories with more than 10 000 files, which immediately excludes cache directories (including library code) from indexing, even if you un-ignore it in `.cursorignore`.
- ~~Cursor doesn't index folders in a workspace, besides the initial one, so you can't open only the projects you want to index in the workspace.~~ (while Cursor now supports multiple directories in a workspace, it indexes them separately, so it still doesn't have insight into library code that's in another directory).
- It's annoying to open a parent directory just to get indexing to work, as that slows down the IDE, and makes the whole UI more messy (since you see all the directories in the file pane and the Git repo view).
- If you just open a repo in Cursor it won't have context on the functions your code is calling, since it can't see their definitions, so it will halucinate a lot.

## Use

This repo is not meant to be cloned and used as such.
It is meant to be used through the [`init.sh`](init.sh) script, which creates the required directory structure in whichever project folder you used it in, then clones the core rules (those that apply to all repos - in contrast to repo-specific rules which you write yourself), and most importantly, clones the libraries that your project uses, so that Cursor indexes them.

> **The script is meant for use on macOS and Linux, it does not work on Windows (unless you're using it in WSL).**

To run the script (which you need to do only once for each project), run the following command in your project's root directory (where the `.git` directory is):

```sh
curl -s https://raw.githubusercontent.com/erazemk/cursor/main/init.sh | sh
```

From then on, you can call the [`update.sh`](.cursor/update.sh) script, which will be placed in your project's `.cursor` directory.

Since you're a security-conscious engineer, I'm sure you've checked out the script before piping it to `sh`.
If not, go do it now, so that you know you haven't run malicious code.

## The resulting project structure

The initialization script creates the following structure in your project's `.cursor` directory:

```
your-project/
├── .cursor/
│   ├── libraries/
│   │   └── (shallowly cloned repositories)
│   ├── rules/
│   │   ├── core.mdc
│   │   └── ...
│   ├── README.md
│   └── update.sh
└── ... (other project files)
```

#### The created files (in the `.cursor` directory) are:

- [`README.md`](.cursor/README.md): It describes what the other files in `.cursor` do and explains what the script does and where to get it.
- `libraries`: A directory to which the initialization script ventors libraries that your project uses, so that Cursor can index them.
  The libraries are only downloaded if the project uses Go, as it checks which libraries your project needs based on your go.mod file.
  Vendoring is needed because this way Cursor can index all the libraries that your project uses.
- [`rules`](.cursor/rules): A collection of core Cursor rules, that can be reused across multiple projects.
  Think of them as general code style guidelines.
  This directory should then also be used by you to add your project-specific rules, to help Cursor write code more relevant to your project and preferred code style.
- [`update.sh`](.cursor/update.sh): A script that you can periodically use to keep your Cursor rules up to date with this repository and which updates your vendored libraries.
  All it does is calls the latest version of the initialization script.

The script also modifies your `.gitignore` file to exclude the `.cursor/libraries` sub-directory.
