use std::borrow::Cow;
use std::collections::BTreeMap;
use std::path::{Component, Path, PathBuf};

use arcstr::ArcStr;
use rolldown_plugin::{
  HookLoadArgs, HookLoadOutput, HookLoadReturn, HookResolveIdArgs, HookResolveIdOutput, HookResolveIdReturn, HookUsage,
  Plugin, PluginContext, PluginContextResolveOptions, SharedLoadPluginContext,
};

#[derive(Debug)]
pub struct VirtualModules {
  sources: BTreeMap<String, ArcStr>,
}

impl VirtualModules {
  pub fn new(sources: BTreeMap<String, String>) -> Self {
    Self {
      sources: sources.into_iter().map(|(id, code)| (id, ArcStr::from(code))).collect(),
    }
  }
}

impl Plugin for VirtualModules {
  fn name(&self) -> Cow<'static, str> {
    Cow::Borrowed("rolldown-ruby:modules")
  }

  fn register_hook_usage(&self) -> HookUsage {
    HookUsage::ResolveId | HookUsage::Load
  }

  async fn resolve_id(&self, ctx: &PluginContext, args: &HookResolveIdArgs<'_>) -> HookResolveIdReturn {
    if self.sources.contains_key(args.specifier) {
      return Ok(Some(HookResolveIdOutput {
        id: ArcStr::from(args.specifier),
        ..Default::default()
      }));
    }

    let Some(importer) = args.importer else {
      return Ok(None);
    };

    if !self.sources.contains_key(importer) || !args.specifier.starts_with('.') {
      return Ok(None);
    }

    let Some(directory) = Path::new(importer).parent() else {
      return Ok(None);
    };

    let joined = directory.join(args.specifier);

    let Some(resolved) = normalize(&joined) else {
      return Ok(None);
    };

    if self.sources.contains_key(&resolved) {
      return Ok(Some(HookResolveIdOutput::from_id(resolved)));
    }

    let Some(absolute) = normalize(&ctx.cwd().join(joined)) else {
      return Ok(None);
    };

    let options = PluginContextResolveOptions {
      import_kind: args.kind,
      skip_self: true,
      custom: args.custom.clone(),
      ..Default::default()
    };

    let Ok(on_disk) = ctx.resolve(&absolute, None, Some(options)).await? else {
      return Ok(None);
    };

    Ok(Some(HookResolveIdOutput {
      id: on_disk.id.as_arc_str().clone(),
      external: Some(on_disk.external),
      normalize_external_id: on_disk.normalize_external_id,
      side_effects: on_disk.side_effects,
      package_json_path: on_disk
        .package_json
        .map(|package| package.realpath().to_string_lossy().into_owned()),
      ..Default::default()
    }))
  }

  async fn load(&self, _ctx: SharedLoadPluginContext, args: &HookLoadArgs<'_>) -> HookLoadReturn {
    let Some(code) = self.sources.get(args.id) else {
      return Ok(None);
    };

    Ok(Some(HookLoadOutput {
      code: code.clone(),
      ..Default::default()
    }))
  }
}

fn normalize(path: &Path) -> Option<String> {
  let mut normalized = PathBuf::new();

  for component in path.components() {
    match component {
      Component::CurDir => {}
      Component::ParentDir => {
        normalized.pop();
      }
      other => normalized.push(other),
    }
  }

  normalized.to_str().map(ToOwned::to_owned)
}
