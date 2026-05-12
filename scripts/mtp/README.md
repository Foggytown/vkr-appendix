## Скрипты для MTP

**[collect_data_for_density.sh](./collect_data_for_density.sh) <модель> <концентрация> <номер модели>** - Запускает на кластере расчет данных в LAMMPS для плотности для модели из *centre/corners/full*, концентрации в формате *al170cu170ni170*, и из 5 моделей берется модель по номеру.

**[collect_data_for_rdf.sh](./collect_data_for_rdf.sh) <модель> <концентрация>** - Запускает на кластере расчет данных в LAMMPS для RDF для соответсвующей модели из *centre/corners/full* и концентрации в формате *al170cu170ni170*.

**[collect_data_for_vacf.sh](./collect_data_for_vacf.sh) <модель> <концентрация>** - Запускает на кластере расчет данных в LAMMPS для VACF для соответсвующей модели из *centre/corners/full* и концентрации в формате *al170cu170ni170*.

**[train_mtp.sh](./train_mtp.sh) <модель> <номер модели> <число ядер>** - Запускает обучение модели MTP из вариантов *centre/corners/full* с нужным номером, используя указанное число ядер.

**[equilibrate_structure.lammps](./equilibrate_structure.lammps)** - Проводит начальное эквилибрирование для данных. *Использование:* Изменить в самом скрипте пути до нужных файлов и запустить с помощью LAMMPS.
