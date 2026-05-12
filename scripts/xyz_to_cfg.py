import numpy as np
import re

def parse_xyz_with_everything(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
    frames = []
    i = 0
    while i < len(lines):
        try:
            num_atoms = int(lines[i].strip())
        except:
            i += 1
            continue
            
        comment = lines[i+1].strip()
        atoms_data = []
        forces = []
        for j in range(i+2, i+2+num_atoms):
            parts = lines[j].split()
            if len(parts) >= 8:
                # symbol x y z index forsex forsey forsez
                symbol = parts[0]
                x, y, z = map(float, parts[1:4])
                fx, fy, fz = map(float, parts[5:8])
                atoms_data.append((symbol, x, y, z))
                forces.append((fx, fy, fz))
        
        # parsing comment
        lattice_match = re.search(r'Lattice="([^"]*)"', comment)
        energy_match = re.search(r'energy=([-\d\.]+)', comment)
        stress_match = re.search(r'stress="([^"]*)"', comment)
        
        # save frame data
        frame_data = {
            'num_atoms': num_atoms,
            'comment': comment,
            'atoms': atoms_data,
            'forces': forces,
            'lattice': None,
            'energy': None,
            'stress': None
        }
        
        if lattice_match:
            lattice_str = lattice_match.group(1)
            lattice_values = list(map(float, lattice_str.split()))
            frame_data['lattice'] = np.array(lattice_values).reshape(3, 3)
        
        if energy_match:
            frame_data['energy'] = float(energy_match.group(1))
        
        if stress_match:
            stress_str = stress_match.group(1)
            stress_values = list(map(float, stress_str.split()))
            frame_data['stress'] = np.array(stress_values).reshape(3, 3)*-1*np.linalg.det(frame_data['lattice'])
        
        frames.append(frame_data)
        i += num_atoms + 2
    
    return frames


frames = parse_xyz_with_everything('data.xyz')

symbol_map={}

with open('data.cfg', 'w') as f:
    for i, frame in enumerate(frames):
        f.write('BEGIN_CFG\n')
        f.write(' Size\n')
        f.write('    {}\n'.format(frame['num_atoms']))
        
        if frame['lattice'] is not None:
            f.write(' Supercell\n')
            for vec in frame['lattice']:
                f.write('    {:.8f} {:.8f} {:.8f}\n'.format(vec[0], vec[1], vec[2]))
        
        f.write(' AtomData: id type x y z fx fy fz\n')
        
        for j, (atom_data, force) in enumerate(zip(frame['atoms'], frame['forces'])):
            symbol, x, y, z = atom_data
            if symbol not in symbol_map:
                symbol_map[symbol]=len(symbol_map)+1
                
            fx, fy, fz = force
            f.write('    {} {} {:.8f} {:.8f} {:.8f} {:.8f} {:.8f} {:.8f}\n'.format(
                j+1, symbol_map[symbol], x, y, z, fx, fy, fz))
        
        if frame['energy'] is not None:
            f.write(' Energy\n')
            f.write('    {:.8f}\n'.format(frame['energy']))
        
        if frame['stress'] is not None:
            stress_tensor = frame['stress']
            stress_voigt = [
                stress_tensor[0, 0],  # xx
                stress_tensor[1, 1],  # yy
                stress_tensor[2, 2],  # zz
                stress_tensor[1, 2],  # yz
                stress_tensor[0, 2],  # xz
                stress_tensor[0, 1]   # xy
            ]
            f.write(' PlusStress: xx yy zz yz xz xy\n')
            f.write('    {:.8f} {:.8f} {:.8f} {:.8f} {:.8f} {:.8f}\n'.format(*stress_voigt))
        
        f.write('END_CFG\n\n')
