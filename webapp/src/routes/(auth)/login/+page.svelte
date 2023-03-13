<script lang="ts">
    import type { ActionData, PageData } from './$types';
    import { z } from 'zod';
    import { EmailConstraint, PasswordConstraint } from '$lib/validation/auth';
    import { loading } from '$lib/store/loadingStore';
    import toast, { Toaster } from 'svelte-french-toast';
    import { enhance, type SubmitFunction } from '$app/forms';

    export let data: PageData;
    export let form: ActionData;

    const redirectUrlParam = data.redirectUrl ? `?redirectUrl=${data.redirectUrl}` : '';
    
    // display error when not using progress enhancements or js is not available
    if (!!form?.actionErrorMessage) toast.error(form.actionErrorMessage);

    const schema = z.object({ 
                        email: EmailConstraint,
                        // use simple string instead of PasswordConstraint so we do not reveal too much
                        password: z.string({ required_error: 'Password is required' }) // ,
                    });

    let isSubmitting = false;
    let clientValidationErrors = {};

    // Spinner will be displayed without delay when we call setLoading
    // this will also disable the buttons instantly
    $: loading.setLoading(isSubmitting);

    const handleSubmit: SubmitFunction = ({ form: hForm, data, action, cancel }) => {
        isSubmitting = true;
        clientValidationErrors = {};

        const formObj = Object.fromEntries(data);
        const validation = schema.safeParse(formObj);

        if (!validation.success) {
            isSubmitting = false;
            cancel();
            clientValidationErrors = validation.error.flatten().fieldErrors;
            return;
        }

        return async ({ result, update }) => {
            //console.log("[login/page.svelte] result = " + JSON.stringify(result, null, 2));

            await update();

            switch (result.type) {
                case 'success':
                case 'failure':
                case 'error':
                    if (!!result?.data?.actionErrorMessage) {
                        toast.error(result?.data.actionErrorMessage);
                    }
                    break;
            }

            isSubmitting = false;
        };
    }
  
    const handleGuestLogin: SubmitFunction = ({ form: hForm, data, action, cancel }) => {
        isSubmitting = true;

        return async ({ result, update }) => {
            await update();
            switch (result.type) {
                case 'failure':
                case 'error':
                    if (!!result?.data?.actionErrorMessage) {
                        toast.error(result?.data.actionErrorMessage);
                    }
                    break;
            }
            isSubmitting = false;
        };
    }
    
</script>

<Toaster />

<div class="w-full max-w-md mx-auto p-4">
<div class="mt-1 bg-white border border-gray-300 rounded-xl shadow-sm dark:bg-gray-800 dark:border-gray-700">
    <div class="p-5 sm:p-3">
        <div class="text-center">
            <h1 class="block text-2xl font-bold text-gray-800 dark:text-white">Log in</h1>
        </div>
        <div class="mt-2">
            <!-- Form -->
            <form method="POST" action="?/login" use:enhance={handleSubmit}>
                <div class="grid gap-y-4">
                    <!-- Form Group -->
                    <div>
                        <label for="email" class="block text-sm mb-1 dark:text-white">Email</label>
                        <div class="relative">
                            <input id="email" name="email" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" required aria-describedby="email-error">
                            <div class="hidden absolute inset-y-0 right-0 flex items-center pointer-events-none pr-3">
                                <svg class="h-5 w-5 text-red-500" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8 4a.905.905 0 0 0-.9.995l.35 3.507a.552.552 0 0 0 1.1 0l.35-3.507A.905.905 0 0 0 8 4zm.002 6a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"/>
                                </svg>
                            </div>
                        </div>
                        <div class="relative">
                        {#if !!clientValidationErrors.email}
                            <p class="text-xs text-red-600 mt-2" id="email-error">{clientValidationErrors.email[0]}</p>
                        {/if}
                        </div>
                    </div>
                    <!-- End Form Group -->

                    <!-- Form Group -->
                    <div>
                        <div class="flex justify-between items-center">
                            <label for="password" class="block text-sm mb-1 dark:text-white">Password</label>
                        </div>
                        <div class="relative">
                            <input type="password" id="password" name="password" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" required aria-describedby="password-error">
                            <div class="hidden absolute inset-y-0 right-0 flex items-center pointer-events-none pr-3">
                                <svg class="h-5 w-5 text-red-500" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                    <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8 4a.905.905 0 0 0-.9.995l.35 3.507a.552.552 0 0 0 1.1 0l.35-3.507A.905.905 0 0 0 8 4zm.002 6a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"/>
                                </svg>
                            </div>
                        </div>
                        <div class="relative">
                        {#if !!clientValidationErrors.password}
                            <p class="text-xs text-red-600 mt-2" id="password-error">{clientValidationErrors.password[0]}</p>
                        {/if}
                        </div>
                    </div>
                    <!-- End Form Group -->

                    {#if !!data.redirectUrl}
                    <input type="hidden" id="redirectUrl" name="redirectUrl" value="{data.redirectUrl}" />
                    {/if}
                    <button type="submit" class="py-3 px-4 inline-flex justify-center items-center gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm dark:focus:ring-offset-gray-800">
                        Log in
                    </button>
                </div>
            </form>
            <!-- End Form -->
        </div>
    </div>

    <div class="grid grid-flow-col mt-3 mb-4 ml-2 mr-2 gap-3 text-sm">
        <div class="col-span-4">
            <p class="text-gray-600 dark:text-gray-400">
                Don't have an account yet?
                <a class="text-blue-600 decoration-2 hover:underline font-medium" href="/register{redirectUrlParam}">
                Sign up here
                </a>
            </p>
        </div>
        <div class="col-span-1">
            <a class="text-blue-600 decoration-2 hover:underline font-medium" href="/resetpassword{redirectUrlParam}">Forgot password?</a>
        </div>
    </div>
</div>
</div>

<div class="w-full max-w-md mx-auto p-2">
    <div class="bg-white rounded-xl dark:bg-gray-80">
    <div class="grid grid-flow-col gap-3 text-center">
        <div class="col-span-3">
            <form method="POST" action="?/guestlogin" use:enhance={handleGuestLogin}>
                <input
                    type="hidden"
                    name="userCode"
                    value="00660e128d94f7a2360e7a24096a7541"
                />
                {#if !!data.redirectUrl}
                <input type="hidden" id="redirectUrl" name="redirectUrl" value="{data.redirectUrl}" />
                {/if}
                <button type="submit" class="w-full p-1 gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm">
                    Log in as Guest 1
                </button>
            </form>
        </div>
        <div class="col-span-3">
            <form method="POST" action="?/guestlogin" use:enhance={handleGuestLogin}>
                <input
                    type="hidden"
                    name="userCode"
                    value="c42b36381ec5f053fdae562cd803abfb"
                />
                {#if !!data.redirectUrl}
                <input type="hidden" id="redirectUrl" name="redirectUrl" value="{data.redirectUrl}" />
                {/if}
                <button type="submit" class="w-full p-1 gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm">
                    Log in as Guest 2
                </button>
            </form>      
        </div>
    </div>    
    </div>
</div>

