nextflow.enable.dsl=2

include { method } from "$launchDir/target/nextflow/main.nf" params(params)

workflow {
  main:
  // todo: update to path on s3
  Channel.fromPath("/home/rcannood/workspace/openproblems/neurips2021_multimodal_viash/output/task1_datasets/**/*.output_mod[12].h5ad")
    | map { [ it.getParent().baseName, it ] }
    | groupTuple
    | map { id, datas -> 
      def fileMap = datas.collectEntries { [ (it.name.split(/\./)[-2]), it ]}
      [ id, [ input_mod1: fileMap.output_mod1, input_mod2: fileMap.output_mod2 ], params ]
    }
    | method
}