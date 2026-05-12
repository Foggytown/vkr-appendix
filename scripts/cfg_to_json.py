from mlip_4 import *

########### functions
def read_cfg (path):       
  """ reads .cfg file in MLIP-2 format to returns list of cfg or calc_cfg """
  e = []
  pos_index = []
  pos = []
  forces = []
  stresses = []
  types = []
  cell = []
  buf = []
  with_energy = False
  with_stresses = False
  with open (path,'r') as f:
      lines = f.readlines()
      for i,line in enumerate(lines):
          if 'Supercell' in line:
              cell_buf = []
              for l in lines[i+1:i+4]:
                  cell_buf.append([float(x) for x in l.split()])
              cell.append(cell_buf)
          elif 'AtomData' in line:
              buf = []
              buf.append(i+1)
              buf.append(i+1+size)
              pos_index.append(buf)
              features_line = line
          elif 'Size' in line:
              size = int(lines[i+1].split()[0])
          elif 'Energy' in line:
              e.append(float(lines[i+1].split()[0]))
              with_energy = True
          elif 'PlusStress' in line:
              stress_buf = []
              for l in range(0,6):
                  stress_buf.append(float(lines[i+1].split()[l]))
              stresses.append(stress_buf)
              with_stresses = True
      for i in pos_index:
          buf_pos = []
          buf_f = []
          buf_types = []
          for line in lines[i[0]:i[1]]:
              buf_pos.append([float(x) for x in line.split()[2:5]])
              if 'fx' in features_line:
                  buf_f.append([float(x) for x in line.split()[5:]])
              buf_types.append(int(line.split()[1]))         
          pos.append(buf_pos)
          if 'fx' in features_line:
              forces.append(buf_f)
          types.append(buf_types)
      cfg_list=[]
      for i in range (len(pos)):
          if len(cell) > 0:
              cfg = Cfg(pos = pos[i], types = types[i], cell = cell[i])
          else:
              cfg = Cfg(pos = pos[i], types= types[i])
          if with_energy:
              if 'fx' in features_line:
                  calc_cfg = CalcCfg(cfg, energy = e[i], forces = forces[i], stress = stresses[i])
              else:
                  calc_cfg = CalcCfg(cfg, energy = e[i])
 
              cfg_list.append(calc_cfg)
          else:
              cfg_list.append(cfg)
  return cfg_list

############### main

cfgs = read_cfg('data.cfg')

func = LossFunction()
i = 0
for s in cfgs:
    func.add(LossCfg(s,1,0.01,0.001))
    i+=1
loss_str=func.to_json_bytes()

with open ('data.json', 'wb') as f:
    f.write(loss_str)

