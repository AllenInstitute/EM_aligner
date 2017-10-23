EM_ALIGNER_LIB_DIR=../..

default: generate_diagnostic_stats \
	Register_montage \
	Register_fine \
	Register_rough \
	Collection_fusion \
	generate_slab_definitions

bin:
	mkdir -p bin

generate_diagnostic_stats: bin Slab_diagnostic_maps.m
	mcc \
	-v \
	-m generate_diagnostic_stats \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/classes \
	-I ${EM_ALIGNER_LIB_DIR}/level_0 \
	-I ${EM_ALIGNER_LIB_DIR}/level_1 \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I .

Register_montage: bin Register_montage.m
	mcc \
	-v \
	-m Register_montage \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/classes \
	-I ${EM_ALIGNER_LIB_DIR}/solver \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api \
	-I ${EM_ALIGNER_LIB_DIR}/level_0 \
	-I ${EM_ALIGNER_LIB_DIR}/level_1 \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I .

Register_rough: bin Register_rough.m
	mcc \
	-v \
	-m Register_rough \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/classes \
	-I ${EM_ALIGNER_LIB_DIR}/solver \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api \
	-I ${EM_ALIGNER_LIB_DIR}/level_0 \
	-I ${EM_ALIGNER_LIB_DIR}/level_1 \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I .

Register_fine: bin Register_fine.m
	mcc \
	-v \
	-m Register_fine \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/classes \
	-I ${EM_ALIGNER_LIB_DIR}/solver \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api \
	-I ${EM_ALIGNER_LIB_DIR}/level_0 \
	-I ${EM_ALIGNER_LIB_DIR}/level_1 \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I .

Collection_fusion: bin Collection_fusion.m
	mcc \
	-v \
	-m Collection_fusion \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/classes \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api \
	-I ${EM_ALIGNER_LIB_DIR}/level_0 \
	-I ${EM_ALIGNER_LIB_DIR}/level_1 \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I .

generate_slab_definitions: bin generate_slab_definitions.m
	mcc \
	-v \
	-m generate_slab_definitions \
	-d bin \
	-I ${EM_ALIGNER_LIB_DIR}/external/jsonlab \
	-I ${EM_ALIGNER_LIB_DIR}/renderer_api

clean:
	rm -f bin/*
