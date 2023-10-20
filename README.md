# Plain scripts

<!-- On GitHub, the index/TOC is automated and located in the left corner -->

<!--## About-->

Curated collection of scripts I have written or [discovered](/unix/x64v-check.awk) (rare) in the last few years, most of which are independent standalone programs (no build config, separate files... — hence the "plain"). The monorepo strategy was chosen for this reason, and to avoid maintaining scattered gists and snippets across the web.

## Content

General notes:
- quality, code style and localization will vary significantly from file to file
- system dependencies are not always checked
- most installable scripts will point to `~/.local/scripts` for convention
- some configurations are stored inside the scripts themselves
- some scripts don't even have usage info

For more information, see the README for each respective directory and the source of each script; not all files are documented.

## Download

It's advisable to clone the repository to `~/.local/scripts` (or other locations, and making a symlink right after); I chose it to avoid littering my home or other places intended for different purposes.

### Cloning specific scripts

With the following snippet, it's possible to avoid cloning the entire repository while also keeping your local files synchronized through `git pull`:

```bash
git clone --depth 1 [--branch bb] --no-checkout url
cd repo
for p in "${repo_paths[@]}":
  git sparse-checkout set  "$p"
  git checkout [bb]
```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

<!-- license filenames supported by github: https://github.com/licensee/licensee/blob/main/lib/licensee/project_files/license_file.rb -->
[MIT](COPYING)
