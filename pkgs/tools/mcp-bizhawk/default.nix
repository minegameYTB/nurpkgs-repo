### mcp-bizhawk: MCP server that drives BizHawk over a socket bridge
### (lua/bridge.lua is loaded in BizHawk's Lua console).
###
### Built from the tagged GitHub source because `dist/` is not committed and
### the npm tarball ships no lockfile — `buildNpmPackage` needs the latter for
### fetchNpmDeps and runs `tsc` for the former.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  ### package.json declares `engines.node >= 22`. nodejs_24 is absent on
  ### older channels (nixos-24.05 in CI) — null fallback like rea.
  nodejs_24 ? null,
  nodejs_22 ? null,
}:

buildNpmPackage {
  pname = "mcp-bizhawk";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "dmang-dev";
    repo = "mcp-bizhawk";
    ### Tag name as `rev`: `tag =` does not exist on older channels
    ### (nixos-24.05 in CI) — same approach as rea.
    rev = "v0.2.0";
    ### fetchFromGitHub goes through fetchzip, which unpacks and re-packs the
    ### archive: the hash is not the one of the raw GitHub tarball.
    hash = "sha256-CdDlbcIjTyeqEE2sbNkIfsIYK83nfDmcCWRRN/FkPWA=";
  };

  ### `prefetch-npm-deps package-lock.json`
  npmDepsHash = "sha256-lb3FIkPcB9t5+YhJc8JRgQ6Z0WYY9Zkgh0EQ4TsX6WE=";

  ### Prefer 24, fall back to 22 where nodejs_24 does not exist (24.05 CI).
  nodejs = if nodejs_24 != null then nodejs_24 else nodejs_22;

  ### Defaults do the right thing: `npm run build` (tsc), then the install hook
  ### packs `dist/` + `lua/`, prunes the dev toolchain and links the
  ### `mcp-bizhawk` bin.

  meta = {
    description = "MCP server that drives BizHawk through a Lua socket bridge";
    homepage = "https://github.com/dmang-dev/mcp-bizhawk";
    license = lib.licenses.mit;
    mainProgram = "mcp-bizhawk";
  };
}
