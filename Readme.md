## Installation

Clone the repository:

```sh
git clone --depth 1 https://github.com/hackr-sh/ghostty-shaders
cd ghostty-shaders
```

Copy your preferred shader file to the Ghostty config directory:

```sh
cp <your-choice>.glsl ~/.config/ghostty/shaders/shader.glsl
```

Add the following line to your `~/.config/ghostty/config` file to enable the custom shader:

```ini
custom-shader = ~/.config/ghostty/shaders/shader.glsl
```

## Matrix rain + shader switcher

`matrix-rain.glsl` draws faint falling Matrix code behind the terminal text.
Tune `OPACITY`, `SPEED`, `TRAIL` and the cell size at the top of the file.

`switch-shader.sh` shows an arrow-key menu of all `.glsl` files under
`~/GhosttyShaders` (override with `GHOSTTY_SHADER_SRC`), copies the chosen one
to `~/.config/ghostty/shaders/shader.glsl`, and can restart Ghostty to load it.

```sh
./switch-shader.sh            # menu, then asks to restart (default: yes)
./switch-shader.sh -n matrix  # filter by name, do not restart
./switch-shader.sh -y         # restart without asking
```

### Add the switcher as an alias

Make a short command, for example `gshader`, so you can run the switcher from
any folder. Use the full path to `switch-shader.sh` in your clone.

**zsh** (macOS default):

```sh
echo 'alias gshader="$HOME/GhosttyShaders/ghostty-shaders/switch-shader.sh"' >> ~/.zshrc
source ~/.zshrc
```

**bash**:

```sh
echo 'alias gshader="$HOME/GhosttyShaders/ghostty-shaders/switch-shader.sh"' >> ~/.bashrc
source ~/.bashrc
```

Then use it like the script:

```sh
gshader            # arrow-key menu, then restart question
gshader -n matrix  # only shaders with "matrix" in the name, no restart
```

New terminal windows get the alias automatically. If your clone is in a
different folder, change the path in the alias. The switcher looks for shaders
in `~/GhosttyShaders` by default. To use a different folder, also add
`export GHOSTTY_SHADER_SRC="/path/to/shaders"` to the same file.
