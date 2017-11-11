import renderapi
from multiprocessing import Process
import time


source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine'
source_owner='gayathri_MM2'

#define source and target
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project':'MM2',
    'client_scripts':'/home/danielk/usr/render/render-ws-java-client/src/main/scripts/',
    'memGB':'2G'
}

render_source = renderapi.connect(**render_source_params)
t0 = time.time()
pm = renderapi.pointmatch.get_matches_within_group(source_name,'1015.0',render=render_source)
print time.time()-t0
