# Ghostty shaders

A collection of custom shaders for the [Ghostty](https://ghostty.org) terminal,
plus a small menu for switching between them.

## Quick start

```sh
git clone https://github.com/benjinamin/ghostty-shaders
cd ghostty-shaders
./install-alias.sh     # adds a `gshader` alias to your shell
source ~/.zshrc        # or open a new terminal
gshader                # pick a shader
```

Pick a shader with the arrow keys and press Enter. The switcher sets up the
Ghostty config for you and offers to restart Ghostty so the shader loads.

## The shader switcher

`switch-shader.sh` shows an arrow-key menu of every `.glsl` file in this repo,
wherever you cloned it. When you pick one, it:

1. copies the shader to `~/.config/ghostty/shaders/shader.glsl`
2. makes sure your Ghostty config (`~/.config/ghostty/config`, or
   `config.ghostty` if you use that name) contains
   `custom-shader = ~/.config/ghostty/shaders/shader.glsl`, adding the line if
   needed and commenting out any other `custom-shader` lines
3. asks to restart Ghostty, since Ghostty only loads shaders at start

```sh
gshader               # menu, then asks to restart (default: yes)
gshader -n matrix     # only shaders with "matrix" in the name, no restart
gshader -y            # restart without asking
gshader --help        # all options
```

Keys: Up/Down (or k/j) to move, Enter to select, q or Esc to quit.
Choose `(off - no shader effect)` at the bottom of the list to turn shaders off.

Restarting closes all Ghostty windows. If you answer no, quit Ghostty fully
(Cmd+Q) and open it again when you are ready.

To read shaders from another folder, set `GHOSTTY_SHADER_SRC`:

```sh
export GHOSTTY_SHADER_SRC="/path/to/shaders"
```

### The `gshader` alias

`install-alias.sh` adds an alias for the switcher to your shell startup file:
`~/.zshrc` for zsh (the macOS default), `~/.bash_profile` for bash on macOS, or
`~/.bashrc` for bash on Linux. The alias points at this clone.

```sh
./install-alias.sh           # alias named gshader
./install-alias.sh shaders   # or choose your own name
```

Running it again is safe. If you move the repo, run it again from the new
location and it updates the existing alias.

## Manual setup

If you prefer not to use the switcher, copy a shader and point Ghostty at it:

```sh
mkdir -p ~/.config/ghostty/shaders
cp <your-choice>.glsl ~/.config/ghostty/shaders/shader.glsl
```

Then add this line to `~/.config/ghostty/config`:

```ini
custom-shader = ~/.config/ghostty/shaders/shader.glsl
```

Restart Ghostty to load it.

## Stacking several shaders: `shader.sh`

`shader.sh` is a second switcher that can chain several shaders, such as
`crt` followed by `bloom`. It writes `custom-shader` lines that point straight
at the files in this repo, and uses `fzf` for its picker when installed.

```sh
./shader.sh set crt bloom   # run crt, then bloom
./shader.sh add drunkard    # add one more to the end
./shader.sh current         # show what is active
./shader.sh off             # remove all shaders
./shader.sh help            # all commands
```

Use one switcher at a time: running `switch-shader.sh` comments out the lines
`shader.sh` added, and `shader.sh` removes the line `switch-shader.sh` added.

## Notes on specific shaders

- `matrix-rain.glsl` draws faint falling Matrix code behind the terminal text.
  Tune `OPACITY`, `SPEED`, `TRAIL` and the cell size at the top of the file.
- `auto-tracking-spotlight` has no `.glsl` extension, so only `shader.sh` lists
  it. Rename it to `auto-tracking-spotlight.glsl` to see it in `gshader` too.
- Preview images for many shaders are in the `theme` folder.

## Adding your own shader

Drop a `.glsl` file into this folder. It shows up in `gshader` the next time you
run it. Ghostty shaders use the Shadertoy format: a
`mainImage(out vec4 fragColor, in vec2 fragCoord)` function, with the terminal
contents available as `iChannel0`.
