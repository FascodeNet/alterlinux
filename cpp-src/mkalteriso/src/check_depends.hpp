#pragma once
#include <alpm.h>
#include "message.hpp"
#include "build_process.hpp"
class check_depends_class{
    public:
        bool check_depends();
        bool compare(String);
    private:
        alpm_pkg_t* get_from_localdb(String pkgname);
        alpm_handle_t* pmhandle;
        alpm_db_t* local_dbkun;
        alpm_list_t* sync_dbskun;
        alpm_pkg_t* get_from_syncdb(String);
        Vector<alpm_db_t*> to_array_dbskun(alpm_list_t* databases);
        void to_array_dbskun(alpm_list_t* databases,Vector<alpm_db_t*>*);
};