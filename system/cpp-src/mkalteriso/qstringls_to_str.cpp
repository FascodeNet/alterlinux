#include "qstringls_to_str.h"
QString qstrls_to_qstr(QStringList lskun){
    QString return_str="";
    for (QString contentkun:lskun) {
        return_str += contentkun + " ";
    }
    return return_str;
}
