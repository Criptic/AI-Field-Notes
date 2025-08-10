/*************************************************************************
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-31-2025

  Use the terminal to clone the repository:
  git -C $WORKSPACE clone https://github.com/Criptic/AI-Field-Notes.git
*************************************************************************/
* Set the path + config.json file name here;
%let pathToConfig = /workspaces/workspace/AI-Field-Notes/config.json;

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

%macro call_gemini(system_prompt, prompt, llm=gemini-2.5-flash-lite, temperature=1, maxOutputTokens=1000, topP=0.8, topK=10, output=work.response);
    /*
        Call the Gemini API with the provided parameters.

        Parameters:
        - system_prompt (str): The system prompt for the model. 
        - user_prompt (str): The user prompt for the model.
        - llm (str): The model to use. Default is gemini-2.5-flash-lite. Values include: gemini-2.5-flash-lite, gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash, gemini-2.0-flash-lite, gemma-3n-e2b-it, gemma-3n-e4b-it, gemma-3-1b-it, gemma-3-4b-it, gemma-3-12b-it, gemma-3-27b-it.
        - temperature (float): Controls the randomness of the output.. Default is 1.
        - max_output_tokens (int): Limits the number of output tokens. Default is 1000.
        - top_p (float): The cumulative proability of tokens to consider when sampling. Default is 0.8.
        - top_k (int): The maximum number of tokens to consider when sampling. Default is 10.
        - output (str): The name of the output data set. Default is work.response.
        
        Returns:
        - data set: A data set containing the response, input tokens, output tokens, and usage metadata.
    */
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
        topK = '"topK":' || &topK. || '}';
        put temperature;
        put maxOutputTokens;
        put topP;
        put topK;
        put '}';
    run;
    filename response temp;

    proc http
        url = "https://generativelanguage.googleapis.com/v1beta/models/&llm.:generateContent?key=&API_KEY."
        in = request
        out = response;
        headers 'Content-Type' = 'application/json';
    quit;

    %if &sys_prochttp_status_code. EQ 200 %then %do;
        %put NOTE: The request was successful, it returned with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
        libname response json;

        data &output.;
            set response.content_parts(keep=Text);
            set response.usageMetaData(keep=promptTokenCount candidatesTokenCount);
            llm = "&llm.";
            temperature = &temperature.;
            maxOutputTokens = &maxOutputTokens.;
            topP = &topP.;
            topK = &topK.;
        run;
    %end;
    %else %do;
        %put ERROR: The request failed with &sys_prochttp_status_code.: &sys_prochttp_status_phrase..;
    %end;

    filename request clear;
    filename response clear;
    libname response clear;
%mend call_gemini;

* Example usage of the call_gemini macro;
%let system_prompt = 'You are an expert in general knowledge question multiple choice answers. You will be given a question with multiple choice answers. You will answer the question with the correct answer, by only returning the letter of the correct answer. If you do not know the answer, provide a 1.';

* Import the simple evaluation dataset;
proc import datafile='/workspaces/workspace/AI-Field-Notes/Datasets/simple-evaluation.csv' out=work.simple_eval dbms=csv replace;
    getnames=yes;
    delimiter=',';
run; quit;

* Loop through the questions and call the Gemini API for each question;
data _null_;
    length args $32000. user_prompt $1500. output_table $32.;
    set work.simple_eval;
    user_prompt = catx('', question, choices);
    output_table = compress('output=work.response_' || _n_);
    args = catx('', '%nrstr(%call_gemini(', "&system_prompt.", ",'", user_prompt, "',", output_table, '))');
    call execute(args);
run;

* Combine the responses into one data set;
data work.responses;
    set work.response_:;
run;

data work.result;
    set work.simple_eval;
    set work.responses;
    output;
    call missing(of _all_);
run;

proc print data=work.result noObs; quit;

/*
* Optional clean up;
%symdel API_KEY;
%sysmacdelete call_gemini;
*/