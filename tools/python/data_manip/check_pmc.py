from pymongo import MongoClient

#check the overlap of tileIds in a pmc and a stack using mongo

z=1335

mongo_collection_name='russelt__Dec_MM500_t2'
#mongo_stack_name='danielk__Reflections__Secs_1015_1099_5_reflections__tile'
mongo_stack_name='danielk__Reflections__Secs_1015_1099_5_reflections_mml6__tile'

client = MongoClient("em-131fs:27017")
db = client.match
collection = client.match[mongo_collection_name]
stack = client.render[mongo_stack_name]

tipm = collection.distinct("qId",{"qGroupId":str(float(z))})
tis = stack.distinct("tileId",{"z":z})
intsct = list((set(tipm)&set(tis)))

print 'for z=%d'%z
print '%d entries from pmc %s'%(len(tipm),mongo_collection_name)
print '%d entries from stack %s'%(len(tis),mongo_stack_name)
print '%d entries in intersection'%len(intsct)

#for it in tipm:
#     cnt = collection.find({"qId":it,"qGroupId":str(float(z))}
