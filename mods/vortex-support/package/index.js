// Vortex loads this entry point directly. It deliberately has no bundled
// dependencies: only Vortex's runtime API and Node's built-in modules are used.
const { spawn } = require("child_process");
const https = require("https");
const path = require("path");
const { fs, util } = require("vortex-api");

const GAME_ID = "fieldsofmistria";
const STEAM_APP_ID = "2142790";
const AIM_CLI = "AIM-cli.exe";
const RELEASE_API = "https://api.github.com/repos/AcTePuKc/Mods-of-Mistria-Installer/releases/latest";
const DOWNLOAD_ROOT = "https://github.com/AcTePuKc/Mods-of-Mistria-Installer/releases/latest/download/";
const DOWNLOAD_URL = `${DOWNLOAD_ROOT}${process.arch === "ia32" ? "AIM-cli-win-x86.exe" : AIM_CLI}`;

function requestBytes(url, onProgress, redirects = 0) {
  return new Promise((resolve, reject) => {
    const request = https.get(url, { headers: { "User-Agent": "AIM-Vortex-Extension" } }, (response) => {
      const status = response.statusCode ?? 0;
      if (status >= 300 && status < 400 && response.headers.location) {
        response.resume();
        if (redirects >= 5) return reject(new Error("Too many redirects while downloading AIM."));
        return resolve(requestBytes(new URL(response.headers.location, url).toString(), onProgress, redirects + 1));
      }
      if (status !== 200) {
        response.resume();
        return reject(new Error(`AIM download failed with HTTP ${status}.`));
      }

      const total = Number(response.headers["content-length"] ?? 0);
      const chunks = [];
      let received = 0;
      response.on("data", (chunk) => {
        chunks.push(chunk);
        received += chunk.length;
        if (total > 0 && onProgress) onProgress(total, received);
      });
      response.on("end", () => resolve(Buffer.concat(chunks)));
      response.on("error", reject);
    });
    request.on("error", reject);
  });
}

function parseVersion(value) {
  const match = /^v?(\d+)\.(\d+)\.(\d+)/.exec(String(value).trim());
  return match ? match.slice(1).map(Number) : undefined;
}

function isNewer(candidate, current) {
  for (let index = 0; index < 3; index += 1) {
    if (candidate[index] !== current[index]) return candidate[index] > current[index];
  }
  return false;
}

async function latestAimVersion() {
  const response = await requestBytes(RELEASE_API);
  return parseVersion(JSON.parse(response.toString("utf8")).tag_name);
}

function runAim(executable, args) {
  return new Promise((resolve, reject) => {
    const child = spawn(executable, args, { shell: false });
    let output = "";
    let errors = "";
    child.stdout.on("data", (chunk) => (output += chunk));
    child.stderr.on("data", (chunk) => (errors += chunk));
    child.on("error", reject);
    child.on("close", (code) => code === 0
      ? resolve(output.trim())
      : reject(new Error(errors || `AIM exited with code ${code}.`)));
  });
}

async function exists(filePath) {
  try {
    await fs.statAsync(filePath);
    return true;
  } catch (_) {
    return false;
  }
}

function sendMissingAim(context, canDownload, action) {
  context.api.sendNotification({
    id: "aim-missing",
    type: "error",
    title: "AIM CLI not found",
    message: "AIM CLI was not found in the Fields of Mistria game directory.",
    actions: canDownload ? [{ title: "Download", action }] : [],
  });
}

function downloadAim(context, discovery) {
  return async () => {
    const notification = { id: "aim-download", type: "activity", title: "Downloading AIM", message: "This may take a minute..." };
    const destination = path.join(discovery.path, AIM_CLI);
    const temporary = `${destination}.download`;
    context.api.dismissNotification("aim-missing");
    context.api.dismissNotification("aim-needs-update");
    context.api.sendNotification({ ...notification, progress: 0 });

    try {
      const bytes = await requestBytes(DOWNLOAD_URL, (total, current) =>
        context.api.sendNotification({ ...notification, progress: (current / total) * 100 }));
      await fs.writeFileAsync(temporary, bytes);
      await fs.removeAsync(destination);
      await fs.renameAsync(temporary, destination);
      context.api.dismissNotification("aim-download");
      context.api.sendNotification({ id: "aim-downloaded", type: "success", message: "AIM download complete." });
    } catch (error) {
      await fs.removeAsync(temporary).catch(() => undefined);
      context.api.dismissNotification("aim-download");
      context.api.showErrorNotification("Could not download AIM", error, {
        allowReport: ["EPERM", "EACCESS", "ENOENT"].includes(error?.code),
      });
    }
  };
}

function init(context) {
  let discoveredGamePath;

  const prepareForModding = async (discovery) => {
    discoveredGamePath = discovery.path;
    await fs.ensureDirAsync(path.join(discovery.path, "mods"));
    const installer = path.join(discovery.path, AIM_CLI);
    const download = downloadAim(context, discovery);
    const hasAim = await exists(installer);

    let newest;
    try {
      newest = await latestAimVersion();
    } catch (_) {
      // AIM remains usable offline; only the download/update action is unavailable.
    }
    if (!hasAim) return sendMissingAim(context, newest !== undefined, download);
    if (!newest) return;

    try {
      const installed = parseVersion(await runAim(installer, ["--version"]));
      if (installed && isNewer(newest, installed)) {
        context.api.sendNotification({
          id: "aim-needs-update",
          type: "warning",
          title: "AIM has an update to install",
          message: "The installed AIM CLI is out of date. Download the current release before deploying mods.",
          actions: [{ title: "Download", action: download }],
        });
      }
    } catch (_) {
      // Deployment will show Vortex's normal error report if the local CLI cannot run.
    }
  };

  context.registerGame({
    id: GAME_ID,
    name: "Fields of Mistria",
    mergeMods: false,
    queryPath: () => util.GameStoreHelper.findByAppId([STEAM_APP_ID]).then((game) => game.gamePath),
    queryModPath: () => "mods",
    logo: "gameart.png",
    executable: () => "FieldsOfMistria.exe",
    requiredFiles: ["FieldsOfMistria.exe"],
    setup: prepareForModding,
    supportedTools: [{
      id: "AIM",
      name: "AIM - Alternative Installer for Mistria",
      requiredFiles: [AIM_CLI],
      executable: () => AIM_CLI,
      relative: true,
      shell: false,
      environment: { EXIT_ON_COMPLETE: "true" },
    }],
    environment: { SteamAPPId: STEAM_APP_ID },
    details: { steamAppId: STEAM_APP_ID },
  });

  context.once(() => {
    context.api.onAsync("did-deploy", async (profileId) => {
      const state = context.api.store.getState();
      const profile = util.getSafe(state, ["persistent", "profiles", profileId], undefined);
      if (profile?.gameId !== GAME_ID) return;

      const tool = util.getSafe(state, ["settings", "gameMode", "discovered", GAME_ID, "tools", "AIM"], undefined);
      // Vortex may not refresh its tool list immediately after AIM is downloaded.
      // The setup path lets the first deployment work without a restart.
      const executable = tool?.path ?? (discoveredGamePath && path.join(discoveredGamePath, AIM_CLI));
      if (!executable || !await exists(executable)) return sendMissingAim(context, false, undefined);

      return context.api.runExecutable(executable, ["--install"], {
        shell: tool?.shell ?? false,
        env: tool?.environment ?? { EXIT_ON_COMPLETE: "true" },
      }).catch((error) => context.api.showErrorNotification(
        "AIM could not install the deployed mods", error,
        { allowReport: ["EPERM", "EACCESS", "ENOENT"].includes(error?.code) },
      ));
    });
  });
  return true;
}

module.exports = { default: init };
