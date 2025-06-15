/*************************************************************************
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-23-2025

  Use the terminal to clone the repository:
  git -C $WORKSPACE clone https://github.com/Criptic/AI-Field-Notes.git
*************************************************************************/
* Set the path + config.json file name here;
%let pathToConfig = /workspaces/workspace/AI-Field-Notes/config.json;

* More on the JSON libname engine: https://documentation.sas.com/doc/en/pgmsascdc/default/lestmtsglobal/n1jfdetszx99ban1rl4zll6tej7j.htm;
%if %sysfunc(fileExist(&pathToConfig.)) %then %do;
    libname config json "&pathToConfig.";
%end;
%else %do;
    %put ERROR: The configuration file can not be found at &pathToConfig. - adjust the macro variable to your environment.;
%end;

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
%let prompt = 'Explain how AI works in a few words';

* Now we add our system prompt;
%let system_prompt = 'You are a pre-school teacher that specialies in breaking down complex topics into easy to digest answer that are appropriate for five year olds.';

* Add the input configuration for the model;
%let temperature = 1;
%let maxOutputTokens = 800;
%let topP = 0.8;
%let topK = 10;
%let candidateCount = 1;

* Generate the request input;
filename request temp;
data _null_;
    file request;
    put '{"system_instruction":{"parts":[{"text":';
    system_prompt = '"' || "&system_prompt." || '"}]},"contents":[{"parts":[{"text":';
    put system_prompt;
    prompt = '"' || "&prompt." || '"}]}],';
    put prompt;
    put '"generationConfig":{';
    temperature = '"temperature":' || &temperature. || ',';
    maxOutputTokens = '"maxOutputTokens":' || &maxOutputTokens. || ',';
    topP = '"topP":' || &topP. || ',';
    topK = '"topK":' || &topK. || ',';
    candidateCount = '"candidateCount":' || &candidateCount. || '}';
    put temperature;
    put maxOutputTokens;
    put topP;
    put topK;
    put candidateCount;
    put '}';
run;
filename response temp;

* More on proc HTTP: https://documentation.sas.com/doc/en/pgmsascdc/default/proc/n0bdg5vmrpyi7jn1pbgbje2atoov.htm;
proc http
    url = "https://generativelanguage.googleapis.com/v1beta/models/&llm.:generateContent?key=&API_KEY."
    in = request
    out = response;
    headers 'Content-Type' = 'application/json';
quit;

%if &sys_prochttp_status_code. EQ 200 %then %do;
	%put NOTE: The request was successful, it returned with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
    libname response json;
    proc print data=response.content_parts(keep=Text) noObs;
    quit;

    proc print data=response.usageMetaData(keep=promptTokenCount candidatesTokenCount) noObs;
    quit;

    proc print data=response.candidates(keep=finishReason avgLogprobs) noObs;
    quit;
%end;
%else %do;
    %put ERROR: The request failed with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
%end;

/*
* Optional clean up;
%symdel API_KEY llm prompt system_prompt temperature maxOutputTokens topP topK candidateCount;
filename request clear;
filename response clear;
libname response clear;
*/