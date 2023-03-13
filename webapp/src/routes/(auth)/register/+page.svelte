<script lang="ts">
    import { z } from 'zod';
    import { EmailConstraint, PasswordConstraint, ConfirmPasswordConstraint, FirstNameConstraint, LastNameConstraint } from '$lib/validation/auth';
    import { loading } from '$lib/store/loadingStore';
    import toast, { Toaster } from 'svelte-french-toast';
    import { enhance, type SubmitFunction } from '$app/forms';

    export let data: PageData;
    export let form: ActionData;

    const redirectUrlParam = data.redirectUrl ? `?redirectUrl=${data.redirectUrl}` : '';

    // display error when not using progress enhancements or js not available
    // the error is returned from page.server.ts/actions
    if (!!form?.actionErrorMessage) toast.error(form.actionErrorMessage);

    const schema = z.object({
                        firstName: FirstNameConstraint,
                        lastName: LastNameConstraint,
                        email: EmailConstraint,
                        password: PasswordConstraint,
                        confirmPassword: ConfirmPasswordConstraint,
                    })
                    .refine((data) => data.password === data.confirmPassword, {
                        message: "Passwords don't match",
                        path: ["confirmPassword"], // path of error
                    });

    let isSubmitting = false;
    let clientValidationErrors = {};

    // Spinner will be displayed without delay when we call setLoading
    // this will also disable the buttons instantly
    $: loading.setLoading(isSubmitting);

    const handleSubmit: SubmitFunction = ({ form: hForm, data, action, cancel }) => {
        isSubmitting = true;
        clientValidationErrors = {};

        console.log("[register/page.svelte] performing client side form validation ");

        const formObj = Object.fromEntries(data);
        const validation = schema.safeParse(formObj);

        if (!validation.success) {
            console.log("[register/page.svelte] client side validation failed ");

            isSubmitting = false;
            cancel();
            clientValidationErrors = validation.error.flatten().fieldErrors;
            return;
        }

        return async ({ result, update }) => {
            console.log("[register/page.svelte] result = " + JSON.stringify(result, null, 2));

            await update();

            switch (result.type) {
                // return { status: 400, data: rest, errors }; from page.server.ts
                // sveltekit will interpret above as http 200 
                // see https://github.com/sveltejs/kit/discussions/5875#discussioncomment-3540263
                // see https://github.com/sveltejs/kit/issues/7233 
                case 'success':

                // return fail(400, ...) from page.server.ts
                case 'failure':
                case 'error':
                    if (!!result?.data?.actionErrorMessage) {
                        toast.error(result?.data.actionErrorMessage);
                    }

                    if (!!result?.data?.errors) {
                        // console.log("[register/page.svelte] errors = " + JSON.stringify(result?.data?.errors, null, 2));
                        clientValidationErrors = result.data.errors;
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
            <h1 class="block text-2xl font-bold text-gray-800 dark:text-white">Sign up</h1>
        </div>
        <div class="mt-2">
    
            <!-- Form -->
            <form method="POST" use:enhance={handleSubmit}>
                <div class="grid gap-y-4">
                    <!-- Grid -->
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 lg:gap-6">
                        <div>
                            <label for="firstName" class="block text-sm mb-1 text-gray-700 font-medium dark:text-white">
                                First Name
                            </label>
                            <input type="text" name="firstName" id="firstName" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400">
                            {#if !!clientValidationErrors?.firstName}
                            <div class="relative">
                                <p class="text-xs text-red-600 mt-2" id="email-error">{clientValidationErrors.firstName[0]}</p>
                            </div>
                            {/if}
                        </div>
                        <div>
                            <label for="lastName" class="block text-sm mb-1 text-gray-700 font-medium dark:text-white">
                                Last Name
                            </label>
                            <input type="text" name="lastName" id="lastName" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-slate-900 dark:border-gray-700 dark:text-gray-400">
                            {#if !!clientValidationErrors?.lastName}
                            <div class="relative">
                                <p class="text-xs text-red-600 mt-2" id="email-error">{clientValidationErrors.lastName[0]}</p>
                            </div>
                            {/if}
                        </div>
                    </div>
                    <!-- End Grid -->

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
                        {#if !!clientValidationErrors?.email}
                        <div class="relative">
                            <p class="text-xs text-red-600 mt-2" id="email-error">{clientValidationErrors.email[0]}</p>
                        </div>
                        {/if}
                    </div>
                    <!-- End Form Group -->
    
                    <!-- Form Group -->
                    <div>
                        <label for="password" class="block text-sm mb-1 dark:text-white">Password</label>
                        <div class="relative">
                            <input type="password" id="password" name="password" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" required aria-describedby="password-error">
                            <div class="hidden absolute inset-y-0 right-0 flex items-center pointer-events-none pr-3">
                                <svg class="h-5 w-5 text-red-500" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8 4a.905.905 0 0 0-.9.995l.35 3.507a.552.552 0 0 0 1.1 0l.35-3.507A.905.905 0 0 0 8 4zm.002 6a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"/>
                                </svg>
                            </div>
                        </div>
                        {#if !!clientValidationErrors?.password}
                        <div class="relative">
                            <p class="text-xs text-red-600 mt-2" id="password-error">{clientValidationErrors.password[0]}</p>
                        </div>
                        {/if}
                    </div>
                    <!-- End Form Group -->
    
                    <!-- Form Group -->
                    <div>
                        <label for="confirmPassword" class="block text-sm mb-1 dark:text-white">Password Confirmation</label>
                        <div class="relative">
                            <input type="password" id="confirmPassword" name="confirmPassword" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" required aria-describedby="confirm-password-error">
                            <div class="hidden absolute inset-y-0 right-0 flex items-center pointer-events-none pr-3">
                                <svg class="h-5 w-5 text-red-500" width="16" height="16" fill="currentColor" viewBox="0 0 16 16" aria-hidden="true">
                                <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zM8 4a.905.905 0 0 0-.9.995l.35 3.507a.552.552 0 0 0 1.1 0l.35-3.507A.905.905 0 0 0 8 4zm.002 6a1 1 0 1 0 0 2 1 1 0 0 0 0-2z"/>
                                </svg>
                            </div>
                        </div>
                        {#if !!clientValidationErrors?.confirmPassword}
                        <div class="relative">
                            <p class="text-xs text-red-600 mt-2" id="password-error">{clientValidationErrors.confirmPassword[0]}</p>
                        </div>
                        {/if}
                    </div>
                    <!-- End Form Group -->
    
                    <!-- Checkbox -->
                    <div class="flex items-center">
                        <!-- <div class="flex">
                            <input id="agreeTerms" name="agreeTerms" type="checkbox" class="shrink-0 mt-0.5 border-gray-200 rounded text-blue-600 pointer-events-none focus:ring-blue-500 dark:bg-gray-800 dark:border-gray-700 dark:checked:bg-blue-500 dark:checked:border-blue-500 dark:focus:ring-offset-gray-800">
                        </div> -->
                        <div class="ml-3">
                            <label for="agreeTerms" class="text-sm dark:text-white">
                                By signing up, I hereby agree to the <a class="text-blue-600 decoration-2 hover:underline font-medium" href="/terms">Terms and Conditions</a>
                            </label>
                        </div>
                    </div>
                    <!-- End Checkbox -->

                    {#if !!data.redirectUrl}
                    <input type="hidden" id="redirectUrl" name="redirectUrl" value="{data.redirectUrl}" />
                    {/if}
                    <button type="submit" class="py-3 px-4 inline-flex justify-center items-center gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all text-sm dark:focus:ring-offset-gray-800">
                        Sign up
                    </button>
                </div>
            </form>
            <!-- End Form -->
        </div>
    </div>
    
    <div class="grid grid-flow-col mt-3 mb-4 ml-2 mr-2 gap-3 text-sm">
        <div class="col-span-6">
            <p class="text-gray-600 dark:text-gray-400">
                Already have an account?
                <a class="text-blue-600 decoration-2 hover:underline font-medium" href="/login{redirectUrlParam}">
                Log in here
                </a>
            </p>
        </div>
    </div>
</div>
</div>