* More on the JSON libname engine: https://documentation.sas.com/doc/en/pgmsascdc/default/lestmtsglobal/n1jfdetszx99ban1rl4zll6tej7j.htm;
libname config json '/workspaces/workspace/AI-Field-Notes/config.json';

* Save the Gemini API-key into a macro variable;
proc sql noPrint;
    select Value into :API_KEY
        from config.allData
            where P1 eq 'gemini_key';
quit;

* Remove the config library;
libname config clear;

* Provide configuration for the model and set the prompt;
%let llm = gemini-2.0-flash;

filename response temp;

* More on proc HTTP: https://documentation.sas.com/doc/en/pgmsascdc/default/proc/n0bdg5vmrpyi7jn1pbgbje2atoov.htm;
proc http
    url = "https://generativelanguage.googleapis.com/v1beta/models/&llm.:generateContent?key=&API_KEY."
    in = '{"contents": [{"parts": [{"text": "Explain how AI works in a few words"}]}]}'
    out = response;
    headers 'Content-Type' = 'application/json';
quit;

%if &sys_prochttp_status_code. EQ 200 %then %do;
	%put NOTE: The request was successful, it returned with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
    libname response json;
    proc print data=response.allData(drop=P V) noObs;
    quit;
%end;
%else %do;
    %put ERROR: The request failed with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
%end;

/*
* Optional clean up;
%symdel API_KEY llm;
filename response clear;
libname response clear;
*/