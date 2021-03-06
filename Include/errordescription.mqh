//+------------------------------------------------------------------+
//|                                             ErrorDescription.mqh |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2012, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property version   "2.00"
//+------------------------------------------------------------------+
//| Возвращает описание кода возврата торгового сервера              |
//+------------------------------------------------------------------+
string TradeServerReturnCodeDescription(int return_code)
  {
//---
   switch(return_code)
     {
      case TRADE_RETCODE_REQUOTE:            return("Реквота");
      case TRADE_RETCODE_REJECT:             return("Запрос отвергнут");
      case TRADE_RETCODE_CANCEL:             return("Запрос отменен трейдером");
      case TRADE_RETCODE_PLACED:             return("Ордер размещен");
      case TRADE_RETCODE_DONE:               return("Заявка выполнена");
      case TRADE_RETCODE_DONE_PARTIAL:       return("Заявка выполнена частично");
      case TRADE_RETCODE_ERROR:              return("Ошибка обработки запроса");
      case TRADE_RETCODE_TIMEOUT:            return("Запрос отменен по истечению времени");
      case TRADE_RETCODE_INVALID:            return("Неправильный запрос");
      case TRADE_RETCODE_INVALID_VOLUME:     return("Неправильный объем в запросе");
      case TRADE_RETCODE_INVALID_PRICE:      return("Неправильная цена в запросе");
      case TRADE_RETCODE_INVALID_STOPS:      return("Неправильные стопы в запросе");
      case TRADE_RETCODE_TRADE_DISABLED:     return("Торговля запрещена");
      case TRADE_RETCODE_MARKET_CLOSED:      return("Рынок закрыт");
      case TRADE_RETCODE_NO_MONEY:           return("Нет достаточных денежных средств для выполнения запроса");
      case TRADE_RETCODE_PRICE_CHANGED:      return("Цены изменились");
      case TRADE_RETCODE_PRICE_OFF:          return("Отсутствуют котировки для обработки запроса");
      case TRADE_RETCODE_INVALID_EXPIRATION: return("Неверная дата истечения ордера в запросе");
      case TRADE_RETCODE_ORDER_CHANGED:      return("Состояние ордера изменилось");
      case TRADE_RETCODE_TOO_MANY_REQUESTS:  return("Слишком частые запросы");
      case TRADE_RETCODE_NO_CHANGES:         return("В запросе нет изменений");
      case TRADE_RETCODE_SERVER_DISABLES_AT: return("Автотрейдинг запрещен сервером");
      case TRADE_RETCODE_CLIENT_DISABLES_AT: return("Автотрейдинг запрещен клиентским терминалом");
      case TRADE_RETCODE_LOCKED:             return("Запрос заблокирован для обработки");
      case TRADE_RETCODE_FROZEN:             return("Ордер или позиция заморожены");
      case TRADE_RETCODE_INVALID_FILL:       return("Указан неподдерживаемый тип исполнения ордера по остатку");
      case TRADE_RETCODE_CONNECTION:         return("Нет соединения с торговым сервером");
      case TRADE_RETCODE_ONLY_REAL:          return("Операция разрешена только для реальных счетов");
      case TRADE_RETCODE_LIMIT_ORDERS:       return("Достигнут лимит на количество отложенных ордеров");
      case TRADE_RETCODE_LIMIT_VOLUME:       return("Достигнут лимит на объем ордеров и позиций для данного символа");
     }
//---
   return("Неизвестный код ответа на торговый запрос");
  }
//+------------------------------------------------------------------+
//| Возвращает описание кода ошибки времени выполнения               |
//+------------------------------------------------------------------+
string ErrorDescription(int err_code)
  {
//---
   switch(err_code)
     {
      case ERR_SUCCESS:                      return("Операция выполнена успешно");
      case ERR_INTERNAL_ERROR:               return("Неожиданная внутренняя ошибка");
      case ERR_WRONG_INTERNAL_PARAMETER:     return("Ошибочный параметр при внутреннем вызове функции клиентского терминала");
      case ERR_INVALID_PARAMETER:            return("Ошибочный параметр при вызове системной функции");
      case ERR_NOT_ENOUGH_MEMORY:            return("Недостаточно памяти для выполнения системной функции");
      case ERR_STRUCT_WITHOBJECTS_ORCLASS:   return("Структура содержит объекты строк и/или динамических массивов и/или структуры с такими объектами и/или классы");
      case ERR_INVALID_ARRAY:                return("Массив неподходящего типа, неподходящего размера или испорченный объект динамического массива");
      case ERR_ARRAY_RESIZE_ERROR:           return("Недостаточно памяти для перераспределения массива либо попытка изменения размера статического массива");
      case ERR_STRING_RESIZE_ERROR:          return("Недостаточно памяти для перераспределения строки");
      case ERR_NOTINITIALIZED_STRING:        return("Неинициализированная строка");
      case ERR_INVALID_DATETIME:             return("Неправильное значение даты и/или времени");
      case ERR_ARRAY_BAD_SIZE:               return("Запрашиваемый размер массива превышает 2 гигабайта");
      case ERR_INVALID_POINTER:              return("Ошибочный указатель");
      case ERR_INVALID_POINTER_TYPE:         return("Ошибочный тип указателя");
      case ERR_FUNCTION_NOT_ALLOWED:         return("Системная функция не разрешена для вызова");
      //--- графики
      case ERR_CHART_WRONG_ID:               return("Ошибочный идентификатор графика");
      case ERR_CHART_NO_REPLY:               return("График не отвечает");
      case ERR_CHART_NOT_FOUND:              return("График не найден");
      case ERR_CHART_NO_EXPERT:              return("У графика нет эксперта, который мог бы обработать событие");
      case ERR_CHART_CANNOT_OPEN:            return("Ошибка открытия графика");
      case ERR_CHART_CANNOT_CHANGE:          return("Ошибка при изменении для графика символа и периода");
      case ERR_CHART_CANNOT_CREATE_TIMER:    return("Ошибка при создании таймера");
      case ERR_CHART_WRONG_PROPERTY:         return("Ошибочный идентификатор свойства графика");
      case ERR_CHART_SCREENSHOT_FAILED:      return("Ошибка при создании скриншота");
      case ERR_CHART_NAVIGATE_FAILED:        return("Ошибка навигации по графику");
      case ERR_CHART_TEMPLATE_FAILED:        return("Ошибка при применении шаблона");
      case ERR_CHART_WINDOW_NOT_FOUND:       return("Подокно, содержащее указанный индикатор, не найдено");
      case ERR_CHART_INDICATOR_CANNOT_ADD:   return("Ошибка при добавлении индикатора на график");
      case ERR_CHART_INDICATOR_CANNOT_DEL:   return("Ошибка при удалении индикатора с графика");
      case ERR_CHART_INDICATOR_NOT_FOUND:    return("Индикатор не найден на указанном графике");
      case 4022:                             return("В процессе выполнения какой-либо встроенной функции был обнаружен ненулевой стоп-флаг");
      //--- графические объекты	
      case ERR_OBJECT_ERROR:                 return("Ошибка при работе с графическим объектом");
      case ERR_OBJECT_NOT_FOUND:             return("Графический объект не найден");
      case ERR_OBJECT_WRONG_PROPERTY:        return("Ошибочный идентификатор свойства графического объекта");
      case ERR_OBJECT_GETDATE_FAILED:        return("Невозможно получить дату, соответствующую значению");
      case ERR_OBJECT_GETVALUE_FAILED:       return("Невозможно получить значение, соответствующее дате");
      ///--- MarketInfo	
      case ERR_MARKET_UNKNOWN_SYMBOL:        return("Неизвестный символ");
      case ERR_MARKET_NOT_SELECTED:          return("Символ не выбран в MarketWatch");
      case ERR_MARKET_WRONG_PROPERTY:        return("Ошибочный идентификатор свойства символа");
      case ERR_MARKET_LASTTIME_UNKNOWN:      return("Время последнего тика неизвестно (тиков не было)");
      case ERR_MARKET_SELECT_ERROR:          return("Ошибка добавления или удаления символа в MarketWatch");
      //--- доступ к истории	
      case ERR_HISTORY_NOT_FOUND:            return("Запрашиваемая история не найдена");
      case ERR_HISTORY_WRONG_PROPERTY:       return("Ошибочный идентификатор свойства истории");
      case ERR_HISTORY_TIMEOUT:              return("Превышен таймаут при запросе истории");
      case ERR_HISTORY_BARS_LIMIT:           return("Количество запрашиваемых баров ограничено настройками терминала");
      case ERR_HISTORY_LOAD_ERRORS:          return("Множество ошибок при загрузке истории");
      case ERR_HISTORY_SMALL_BUFFER:         return("Принимающий массив слишком мал чтобы вместить все запрошенные данные");
      //--- глобальные переменные
      case ERR_GLOBALVARIABLE_NOT_FOUND:     return("Глобальная переменная клиентского терминала не найдена");
      case ERR_GLOBALVARIABLE_EXISTS:        return("Глобальная переменная клиентского терминала с таким именем уже существует");
	  case ERR_GLOBALVARIABLE_NOT_MODIFIED:  return("Не было модификаций глобальных переменных");
      case ERR_MAIL_SEND_FAILED:             return("Не удалось отправить письмо");
      case ERR_PLAY_SOUND_FAILED:            return("Не удалось воспроизвести звук");
      case ERR_MQL5_WRONG_PROPERTY:          return("Ошибочный идентификатор свойства программы");
      case ERR_TERMINAL_WRONG_PROPERTY:      return("Ошибочный идентификатор свойства терминала");
      case ERR_FTP_SEND_FAILED:              return("Не удалось отправить файл по ftp");
      case ERR_NOTIFICATION_SEND_FAILED:     return("Не удалось отправить уведомление");
      //--- буферы пользовательских индикаторов	
      case ERR_BUFFERS_NO_MEMORY:            return("Недостаточно памяти для распределения индикаторных буферов");
      case ERR_BUFFERS_WRONG_INDEX:          return("Ошибочный индекс своего индикаторного буфера");
      ///--- свойства пользовательских индикаторов	
      case ERR_CUSTOM_WRONG_PROPERTY:        return("Ошибочный идентификатор свойства пользовательского индикатора");
      ///--- Account	
      case ERR_ACCOUNT_WRONG_PROPERTY:       return("Ошибочный идентификатор свойства счета");
      case ERR_TRADE_WRONG_PROPERTY:         return("Ошибочный идентификатор свойства торговли");
      case ERR_TRADE_DISABLED:               return("Торговля для эксперта запрещена");
      case ERR_TRADE_POSITION_NOT_FOUND:     return("Позиция не найдена");
      case ERR_TRADE_ORDER_NOT_FOUND:        return("Ордер не найден");
      case ERR_TRADE_DEAL_NOT_FOUND:         return("Сделка не найдена");
      case ERR_TRADE_SEND_FAILED:            return("Не удалось отправить торговый запрос");
      ///--- индикаторы	
      case ERR_INDICATOR_UNKNOWN_SYMBOL:     return("Неизвестный символ");
      case ERR_INDICATOR_CANNOT_CREATE:      return("Индикатор не может быть создан");
      case ERR_INDICATOR_NO_MEMORY:          return("Недостаточно памяти для добавления индикатора");
      case ERR_INDICATOR_CANNOT_APPLY:       return("Индикатор не может быть применен к другому индикатору");
      case ERR_INDICATOR_CANNOT_ADD:         return("Ошибка при добавлении индикатора");
      case ERR_INDICATOR_DATA_NOT_FOUND:     return("Запрошенные данные не найдены");
      case ERR_INDICATOR_WRONG_HANDLE:       return("Ошибочный хэндл индикатора");
      case ERR_INDICATOR_WRONG_PARAMETERS:   return("Неправильное количество параметров при создании индикатора");
      case ERR_INDICATOR_PARAMETERS_MISSING: return("Отсутствуют параметры при создании индикатора");
      case ERR_INDICATOR_CUSTOM_NAME:        return("Первым параметром в массиве должно быть имя пользовательского индикатора");
      case ERR_INDICATOR_PARAMETER_TYPE:     return("Неправильный тип параметра в массиве при создании индикатора");
      case ERR_INDICATOR_WRONG_INDEX:        return("Ошибочный индекс запрашиваемого индикаторного буфера");
      //--- стакан цен	
      case ERR_BOOKS_CANNOT_ADD:             return("Стакан цен не может быть добавлен");
      case ERR_BOOKS_CANNOT_DELETE:          return("Стакан цен не может быть удален");
      case ERR_BOOKS_CANNOT_GET:             return("Данные стакана цен не могут быть получены");
      case ERR_BOOKS_CANNOT_SUBSCRIBE:       return("Ошибка при подписке на получение новых данных стакана цен");
      //--- файловые операции	
      case ERR_TOO_MANY_FILES:               return("Не может быть открыто одновременно более 64 файлов");
      case ERR_WRONG_FILENAME:               return("Недопустимое имя файла");
      case ERR_TOO_LONG_FILENAME:            return("Слишком длинное имя файла");
      case ERR_CANNOT_OPEN_FILE:             return("Ошибка открытия файла");
      case ERR_FILE_CACHEBUFFER_ERROR:       return("Недостаточно памяти для кеша чтения");
      case ERR_CANNOT_DELETE_FILE:           return("Ошибка удаления файла");
      case ERR_INVALID_FILEHANDLE:           return("Файл с таким хэндлом уже был закрыт, либо не открывался вообще");
      case ERR_WRONG_FILEHANDLE:             return("Ошибочный хэндл файла");
      case ERR_FILE_NOTTOWRITE:              return("Файл должен быть открыт для записи");
      case ERR_FILE_NOTTOREAD:               return("Файл должен быть открыт для чтения");
      case ERR_FILE_NOTBIN:                  return("Файл должен быть открыт как бинарный");
      case ERR_FILE_NOTTXT:                  return("Файл должен быть открыт как текстовый");
      case ERR_FILE_NOTTXTORCSV:             return("Файл должен быть открыт как текстовый или CSV");
      case ERR_FILE_NOTCSV:                  return("Файл должен быть открыт как CSV");
      case ERR_FILE_READERROR:               return("Ошибка чтения файла");
      case ERR_FILE_BINSTRINGSIZE:           return("Должен быть указан размер строки, так как файл открыт как бинарный");
      case ERR_INCOMPATIBLE_FILE:            return("Для строковых массивов должен быть текстовый файл, для остальных – бинарный");
      case ERR_FILE_IS_DIRECTORY:            return("Это не файл, а директория");
      case ERR_FILE_NOT_EXIST:               return("Файл не существует");
      case ERR_FILE_CANNOT_REWRITE:          return("Файл не может быть переписан");
      case ERR_WRONG_DIRECTORYNAME:          return("Ошибочное имя директории");
      case ERR_DIRECTORY_NOT_EXIST:          return("Директория не существует");
      case ERR_FILE_ISNOT_DIRECTORY:         return("Это файл, а не директория");
      case ERR_CANNOT_DELETE_DIRECTORY:      return("Директория не может быть удалена");
      case ERR_CANNOT_CLEAN_DIRECTORY:       return("Не удалось очистить директорию (возможно, один или несколько файлов заблокированы и операция удаления не удалась)");
      case ERR_FILE_WRITEERROR:              return("Не удалось записать ресурс в файл");
      //--- преобразование строк	
      case ERR_NO_STRING_DATE:               return("В строке нет даты");
      case ERR_WRONG_STRING_DATE:            return("В строке ошибочная дата");
      case ERR_WRONG_STRING_TIME:            return("В строке ошибочное время");
      case ERR_STRING_TIME_ERROR:            return("Ошибка преобразования строки в дату");
      case ERR_STRING_OUT_OF_MEMORY:         return("Недостаточно памяти для строки");
      case ERR_STRING_SMALL_LEN:             return("Длина строки меньше, чем ожидалось");
      case ERR_STRING_TOO_BIGNUMBER:         return("Слишком большое число, больше, чем ULONG_MAX");
      case ERR_WRONG_FORMATSTRING:           return("Ошибочная форматная строка");
      case ERR_TOO_MANY_FORMATTERS:          return("Форматных спецификаторов больше, чем параметров");
      case ERR_TOO_MANY_PARAMETERS:          return("Параметров больше, чем форматных спецификаторов");
      case ERR_WRONG_STRING_PARAMETER:       return("Испорченный параметр типа string");
      case ERR_STRINGPOS_OUTOFRANGE:         return("Позиция за пределами строки");
      case ERR_STRING_ZEROADDED:             return("К концу строки добавлен 0, бесполезная операция");
      case ERR_STRING_UNKNOWNTYPE:           return("Неизвестный тип данных при конвертации в строку");
      case ERR_WRONG_STRING_OBJECT:          return("Испорченный объект строки");
      //--- работа с массивами	
      case ERR_INCOMPATIBLE_ARRAYS:          return("Копирование несовместимых массивов. Строковый массив может быть скопирован только в строковый, а числовой массив – в числовой");
      case ERR_SMALL_ASSERIES_ARRAY:         return("Приемный массив объявлен как AS_SERIES, и он недостаточного размера");
      case ERR_SMALL_ARRAY:                  return("Слишком маленький массив, стартовая позиция за пределами массива");
      case ERR_ZEROSIZE_ARRAY:               return("Массив нулевой длины");
      case ERR_NUMBER_ARRAYS_ONLY:           return("Должен быть числовой массив");
      case ERR_ONEDIM_ARRAYS_ONLY:           return("Должен быть одномерный массив");
      case ERR_SERIES_ARRAY:                 return("Таймсерия не может быть использована");
      case ERR_DOUBLE_ARRAY_ONLY:            return("Должен быть массив типа double");
      case ERR_FLOAT_ARRAY_ONLY:             return("Должен быть массив типа float");
      case ERR_LONG_ARRAY_ONLY:              return("Должен быть массив типа long");
      case ERR_INT_ARRAY_ONLY:               return("Должен быть массив типа int");
      case ERR_SHORT_ARRAY_ONLY:             return("Должен быть массив типа short");
      case ERR_CHAR_ARRAY_ONLY:              return("Должен быть массив типа char");
      //--- работа с OpenCL	
      case ERR_OPENCL_NOT_SUPPORTED:         return("Функции OpenCL на данном компьютере не поддерживаются");
      case ERR_OPENCL_INTERNAL:              return("Внутренняя ошибка при выполнении OpenCL");
      case ERR_OPENCL_INVALID_HANDLE:        return("Неправильный хэндл OpenCL");
      case ERR_OPENCL_CONTEXT_CREATE:        return("Ошибка при создании контекста OpenCL");
      case ERR_OPENCL_QUEUE_CREATE:          return("Ошибка создания очереди выполнения в OpenCL");
      case ERR_OPENCL_PROGRAM_CREATE:        return("Ошибка при компиляции программы OpenCL");
      case ERR_OPENCL_TOO_LONG_KERNEL_NAME:  return("Слишком длинное имя точки входа (кернел OpenCL)");
      case ERR_OPENCL_KERNEL_CREATE:         return("Ошибка создания кернел - точки входа OpenCL");
      case ERR_OPENCL_SET_KERNEL_PARAMETER:  return("Ошибка при установке параметров для кернел OpenCL (точки входа в программу OpenCL)");
      case ERR_OPENCL_EXECUTE:               return("Ошибка выполнения программы OpenCL");
      case ERR_OPENCL_WRONG_BUFFER_SIZE:     return("Неверный размер буфера OpenCL");
      case ERR_OPENCL_WRONG_BUFFER_OFFSET:   return("Неверное смещение в буфере OpenCL");
      case ERR_OPENCL_BUFFER_CREATE:         return("Ошибка создания буфера OpenCL");
      default: if(err_code>=ERR_USER_ERROR_FIRST && err_code<ERR_USER_ERROR_LAST)
         return("Ошибка, заданная пользователем "+string(err_code-ERR_USER_ERROR_FIRST));
     }
//---
   return("Неизвестная ошибка");
  }
//+------------------------------------------------------------------+
