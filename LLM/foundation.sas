/*************************************************************************
  Please check out the blog post for more details:
  https://davidweik.substack.com/p/ai-field-notes-cw-29-2025

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
%let system_prompt = 'You are a pre-school teacher that specialies in breaking down complex topics into easy to digest answer that are appropriate for five year olds.';
%let user_prompt = 'Explain how AI works in a few words';
%call_gemini(&user_prompt., &system_prompt.)
proc print data=work.response noObs; quit;

/*
* Optional clean up;
%symdel API_KEY;
%sysmacdelete call_gemini;
*/