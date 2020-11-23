#include "custom_exec.hpp"
using namespace std;
namespace FascodeUtil{
    int custom_exec_v(std::vector<std::string> args){
        char** argskun=NULL;
        argskun=new char*[args.size() + 2];
        for(size_t i=0;i<args.size();i++){
            argskun[i]=(char*)args[i].c_str();
        }
        argskun[args.size()]=NULL;
        pid_t pid = fork();
        if(pid < 0){
            perror("fork");
            exit(-1);
        }else if(pid == 0){
            execvp(argskun[0],argskun);
            perror("exec");
            exit(-1);
        }
        int status;
        pid_t resultkun=waitpid(pid,&status,0);
        if(resultkun < 0){
            perror("waitpid error");
            exit(-1);
        }
        return status;
    }
    int custom_exec_v(std::string fname,std::vector<std::string> args){
        std::vector<std::string> n_vector;
        n_vector.push_back(fname);
        for(string i:args){
            n_vector.push_back(i);
        }
        return custom_exec_v(n_vector);
    }
    int custom_exec_v(char* fname,std::vector<std::string> args){
        std::string fname_str=fname;
        return custom_exec_v(fname_str,args);
    }
    template<class... T> 
    int custom_exec(T... args){
        	std::vector<std::string> args_vector;
	    for(string i : std::initializer_list<string>{args...}){
    		args_vector.push_back(i);
    	}
    	return custom_exec_v(args_vector);
    }
    int custom_exec_v_no_wait(std::vector<std::string> args){
        char** argskun=NULL;
        argskun=new char*[args.size() + 2];
        for(size_t i=0;i<args.size();i++){
                argskun[i]=(char*)args[i].c_str();
        }
        argskun[args.size()]=NULL;
        pid_t pid = fork();
        if(pid < 0){
            perror("fork");
            exit(-1);
        }else if(pid == 0){
            execvp(argskun[0],argskun);
            perror("exec");
            exit(-1);
        }
	    return 0;
    }
    template<class... T> 
    int custom_exec_no_wait(T... args){
    	std::vector<std::string> args_vector;
    	for(string i : std::initializer_list<string>{args...}){
		    args_vector.push_back(i);
	    }
	    return custom_exec_v_no_wait(args_vector);
    }
}   