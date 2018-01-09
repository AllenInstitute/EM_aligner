import json
import copy
import os

stacks = []
#stacks.append('Substack_x_0_240000_y_0_240000')
#stacks.append('Substack_x_0_200000_y_0_200000')
#stacks.append('Substack_x_0_160000_y_0_160000')
#stacks.append('Substack_x_0_120000_y_0_120000')
#stacks.append('Substack_x_0_80000_y_0_80000')
#stacks.append('Substack_x_0_40000_y_0_40000')
#stacks.append('Substack_x_40000_80000_y_40000_80000')
#stacks.append('Substack_x_80000_120000_y_80000_120000')
#stacks.append('Substack_x_120000_160000_y_120000_160000')
#stacks.append('Substack_x_160000_200000_y_160000_200000')
#stacks.append('Substack_x_200000_240000_y_200000_240000')
stacks.append('Substack_x_80000_120000_y_0_80000')
stacks.append('Substack_x_120000_160000_y_0_80000')
stacks.append('Substack_x_160000_200000_y_0_80000')
stacks.append('Substack_x_200000_240000_y_0_80000')

lams = [1e9,1e5,1e3,1e1]

fin  = open('../jsons_dk/input.json').read()
injson = json.loads(fin)

for stack in stacks:
    outjson = copy.copy(injson)
    outjson['source_collection']['stack'] = stack
    for lam in lams:
        outjson['solver_options']['lambda'] = lam
        outjson['solver_options']['edge_lambda'] = lam
        tmp = stack+'_fine_lam_%0.0e'%lam
        tmp = tmp.replace('+','')
        tmp = tmp.replace('-','m')
        outjson['target_collection']['stack'] = tmp
        fp = open('./input.json','w')
        json.dump(outjson,fp,indent=4, separators=(',', ': '),sort_keys=True)
        fp.close()
        os.system('input="./input.json" ./em_solver.sh')
    
