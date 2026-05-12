## Скрипты для DeePMD

**[collect_data_for_density.sh](./collect_data_for_density.sh) <модель> <концентрация>** - Запускает на кластере расчет данных в LAMMPS для плотности для соответсвующей модели из *centre/corners/full* и концентрации в формате *al170cu170ni170*.

**[collect_data_for_rdf.sh](./collect_data_for_rdf.sh) <модель> <концентрация>** - Запускает на кластере расчет данных в LAMMPS для RDF для соответсвующей модели из *centre/corners/full* и концентрации в формате *al170cu170ni170*.

**[collect_data_for_vacf.sh](./collect_data_for_vacf.sh) <модель> <концентрация>** - Запускает на кластере расчет данных в LAMMPS для VACF для соответсвующей модели из *centre/corners/full* и концентрации в формате *al170cu170ni170*.

**[train_dp.sh](./train_dp.sh)** - Запускает обучение модели DeePMD. *Использование:* Изменить в самом скрипте пути до нужных файлов и запустить. *(скрипт был предоставлен коллегами)*

**[equilibrate_structure.lammps](./equilibrate_structure.lammps)** - Проводит начальное эквилибрирование для данных. *Использование:* Изменить в самом скрипте пути до нужных файлов и запустить с помощью LAMMPS.
