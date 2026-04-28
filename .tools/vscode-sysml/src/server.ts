import { createConnection, ProposedFeatures } from "vscode-languageserver/node.js";
import { inject } from "langium";
import { NodeFileSystem } from "langium/node";
import {
  createDefaultModule,
  createDefaultSharedModule,
  startLanguageServer,
  type LangiumServices,
  type DefaultSharedModuleContext,
} from "langium/lsp";
import {
  SysmlGeneratedModule,
  SysmlGeneratedSharedModule,
} from "../../sysml/generated/module.js";

const connection = createConnection(ProposedFeatures.all);

const context: DefaultSharedModuleContext = {
  connection,
  ...NodeFileSystem,
};

const shared = inject(
  createDefaultSharedModule(context),
  SysmlGeneratedSharedModule,
);

const Sysml = inject(createDefaultModule({ shared }), SysmlGeneratedModule);

shared.ServiceRegistry.register(Sysml as unknown as LangiumServices);

startLanguageServer(shared);
