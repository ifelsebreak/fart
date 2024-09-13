import 'package:macros/macros.dart';
import 'package:macros/src/executor.dart';
import 'package:macros/src/executor/introspection_impls.dart';
import 'package:macros/src/executor/remote_instance.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

import 'shared.dart';

Future<void> runBenchmarks(MacroExecutor executor, Uri macroUri) async {
  final introspector = SimpleTypePhaseIntrospector(identifiers: {
    Uri.parse('dart:core'): {
      'int': intIdentifier,
      'String': stringIdentifier,
    },
    Uri.parse('package:flutter/widgets.dart'): {
      'BuildContext': buildContextIdentifier,
      'StatelessWidget': statelessWidgetIdentifier,
      'Widget': widgetIdentifier,
    }
  });
  final identifierDeclarations = <Identifier, Declaration>{};
  final instantiateBenchmark =
      FunctionalWidgetInstantiateBenchmark(executor, macroUri);
  await instantiateBenchmark.report();
  final instanceId = instantiateBenchmark.instanceIdentifier;
  final typesBenchmark = FunctionalWidgetTypesPhaseBenchmark(
      executor, macroUri, instanceId, introspector);
  await typesBenchmark.report();
  BuildAugmentationLibraryBenchmark.reportAndPrint(
      executor,
      [if (typesBenchmark.result != null) typesBenchmark.result!],
      identifierDeclarations);
}

class FunctionalWidgetInstantiateBenchmark extends AsyncBenchmarkBase {
  final MacroExecutor executor;
  final Uri macroUri;
  late MacroInstanceIdentifier instanceIdentifier;

  FunctionalWidgetInstantiateBenchmark(this.executor, this.macroUri)
      : super('FunctionalWidgetInstantiate');

  Future<void> run() async {
    instanceIdentifier = await executor.instantiateMacro(
        macroUri, 'FunctionalWidget', '', Arguments([], {}));
  }
}

class FunctionalWidgetTypesPhaseBenchmark extends AsyncBenchmarkBase {
  final MacroExecutor executor;
  final Uri macroUri;
  final MacroInstanceIdentifier instanceIdentifier;
  final TypePhaseIntrospector introspector;
  MacroExecutionResult? result;

  FunctionalWidgetTypesPhaseBenchmark(
      this.executor, this.macroUri, this.instanceIdentifier, this.introspector)
      : super('FunctionalWidgetTypesPhase');

  Future<void> run() async {
    if (instanceIdentifier.shouldExecute(
        DeclarationKind.function, Phase.types)) {
      result = await executor.executeTypesPhase(
          instanceIdentifier, myFunction, introspector);
    }
  }
}

final buildContextIdentifier =
    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'BuildContext');
final statelessWidgetIdentifier =
    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'StatelessWidget');
final buildContextType = NamedTypeAnnotationImpl(
    id: RemoteInstance.uniqueId,
    isNullable: false,
    identifier: buildContextIdentifier,
    typeArguments: []);
final widgetIdentifier =
    IdentifierImpl(id: RemoteInstance.uniqueId, name: 'Widget');
final widgetType = NamedTypeAnnotationImpl(
    id: RemoteInstance.uniqueId,
    isNullable: false,
    identifier: widgetIdentifier,
    typeArguments: []);
final myFunction = FunctionDeclarationImpl(
    id: RemoteInstance.uniqueId,
    identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: '_myWidget'),
    library: fooLibrary,
    metadata: [],
    hasBody: true,
    hasExternal: false,
    isGetter: false,
    isOperator: false,
    isSetter: false,
    namedParameters: [
      FormalParameterDeclarationImpl(
        id: RemoteInstance.uniqueId,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'title'),
        isNamed: true,
        isRequired: true,
        library: fooLibrary,
        metadata: [],
        type: stringType,
        style: ParameterStyle.normal,
      ),
    ],
    positionalParameters: [
      FormalParameterDeclarationImpl(
        id: RemoteInstance.uniqueId,
        identifier:
            IdentifierImpl(id: RemoteInstance.uniqueId, name: 'context'),
        isNamed: false,
        isRequired: true,
        library: fooLibrary,
        metadata: [],
        type: buildContextType,
        style: ParameterStyle.normal,
      ),
      FormalParameterDeclarationImpl(
        id: RemoteInstance.uniqueId,
        identifier: IdentifierImpl(id: RemoteInstance.uniqueId, name: 'count'),
        isNamed: false,
        isRequired: true,
        library: fooLibrary,
        metadata: [],
        type: intType,
        style: ParameterStyle.normal,
      ),
    ],
    returnType: widgetType,
    typeParameters: []);
