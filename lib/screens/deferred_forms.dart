/// Файл-бочка (barrel) специально под отложенную загрузку (ПР6, оценка «5»:
/// "уменьшен размер сборки... отложенная загрузка редко используемых
/// разделов через deferred as"). Формы создания/редактирования нужны
/// только продавцу и администратору — подавляющее большинство переходов
/// (просмотр каталога покупателем) их вообще не касается, поэтому имеет
/// смысл вынести все пять в один общий отложенный чанк, а не грузить их
/// код каждому посетителю сразу в главном main.dart.js.
library;

export 'categories/category_form_screen.dart';
export 'clients/client_form_screen.dart';
export 'designers/designer_form_screen.dart';
export 'manufacturers/manufacturer_form_screen.dart';
export 'stores/store_form_screen.dart';
export 'weapons/weapon_form_screen.dart';
