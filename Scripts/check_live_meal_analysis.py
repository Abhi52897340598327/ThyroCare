import os,json,urllib.request,subprocess,tempfile,time,uuid,base64,sys
from pathlib import Path
root=Path(__file__).resolve().parents[1]
if len(sys.argv) != 2:
 raise SystemExit("Usage: python3 Scripts/check_live_meal_analysis.py PUBLIC_OR_SYNTHETIC_FOOD_JPEG (sends photo to Gemini/USDA; uses configured API credits)")
image_path=Path(sys.argv[1])
with tempfile.TemporaryDirectory(prefix='thyrocare-live-ai-') as directory:
 env=dict(os.environ,CARE_DATA_DIRECTORY=directory,HOST='127.0.0.1',PORT='8098')
 with open(directory+'/server.log','w') as log:
  server=subprocess.Popen([str(root/'Backend/.build/debug/Run')],cwd=root/'Backend',env=env,stdout=log,stderr=log)
  try:
   def call(path,body=None,token=None):
    headers={'Content-Type':'application/json'}
    if token:headers['Authorization']='Bearer '+token
    request=urllib.request.Request('http://localhost:8098/v1/'+path,data=json.dumps(body).encode() if body is not None else None,headers=headers)
    with urllib.request.urlopen(request,timeout=120) as response:return json.load(response)
   for _ in range(60):
    try:
     urllib.request.urlopen('http://localhost:8098/health',timeout=1);break
    except Exception:time.sleep(.2)
   a=call('auth/register',{'name':'Synthetic AI Test','email':str(uuid.uuid4())+'@example.test','password':uuid.uuid4().hex})
   pid=a['user']['id'];token=a['token'];mid=str(uuid.uuid4());path=f'patients/{pid}/meals'
   call(path,{'id':mid,'expectedVersion':0,'fields':{'description':'Public stock apple photograph for integration testing','observedDate':'2026-10-24','mealTime':'12:00','hasPhoto':'true'}},token)
   call(path+'/'+mid+'/photo',{'imageBase64':base64.b64encode(image_path.read_bytes()).decode()},token)
   result=call(path+'/'+mid+'/analyze',{'consent':True},token)
   f=result['fields'];print(json.dumps({k:f.get(k) for k in ['analysisStatus','analysisModel','recognizedFoods','estimatedCaloriesKcal','analysisError']},indent=2))
   assert f.get('analysisStatus')=='complete'
   assert f['analysisModel']=='gemini-3.5-flash'
   details=json.loads(f['nutritionDetails']);assert details and all(d['usdaFdcId'] for d in details)
   assert call(path,token=token)[0]['fields']['summary']==f['summary']
   print('PASS: photo upload → Gemini 3.5 Flash → USDA matches → persisted result')
  finally:
   server.terminate();server.wait(timeout=10)
   print("\n".join(l for l in Path(directory+"/server.log").read_text().splitlines() if "Gemini meal recognition failed with status" in l))
