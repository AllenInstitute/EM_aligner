import renderapi

source_name='Secs_1015_1099_5_reflections_mml6'
source_owner='danielk'
scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'

#define source and target
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project':'Reflections',
    'client_scripts':scripts,
    'memGB':'2G'
}
render_source = renderapi.connect(**render_source_params)
renderapi.stack.set_stack_state(source_name, state='COMPLETE', render=render_source)

