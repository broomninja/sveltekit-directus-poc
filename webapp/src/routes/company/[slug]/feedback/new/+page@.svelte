<script lang="ts">
    import type { PageData } from './$types';
    import { browser } from '$app/environment';
    import { enhance, type SubmitFunction } from '$app/forms';
    import { invalidate } from '$app/navigation';
    import ButtonWithTooltip from '$lib/components/ButtonWithTooltip.svelte';
    import toast, { Toaster } from 'svelte-french-toast';
    import DOMPurify from 'isomorphic-dompurify';
    import { z } from 'zod';
    import { TitleConstraint, FeedbackContentConstraint, IdConstraint, SlugConstraint } from '$lib/validation/feedback';
    import { loading } from '$lib/store/loadingStore';
    export let data: PageData;
    export let form: ActionData;

    let { user, company } = data;

    // display error when not using progress enhancements or js not available
    // 'form' is returned from page.server.ts/actions
    if (!!form?.actionErrorMessage) toast.error(form.actionErrorMessage);

    let formData: HTMLFormElement = {
        content: '',
    };

    const schema = z.object({
                            title: TitleConstraint,
                            content: FeedbackContentConstraint,
                            userId: IdConstraint,
                            companyId: IdConstraint,
                            companySlug: SlugConstraint,
                   });

  	const contentMaxLength: number = 1000;
	$: charsRemaining = contentMaxLength - formData.content.length;

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
            console.log(`[/company/[slug]/feedback/new/page.svelte] result = ${JSON.stringify(result, null, 2)}`);

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
                        // console.log(`[/company/[slug]/feedback/new/page.svelte] errors = ${JSON.stringify(result?.data?.errors, null, 2)}`);
                        clientValidationErrors = result.data.errors;
                    }

                    break;
            }
            isSubmitting = false;
        };
    }

</script>

<Toaster />

<!-- Feedback Form -->
<div class="max-w-[85rem] px-4 pt-4 pb-5 sm:px-6 lg:px-8 lg:pb-5 mx-auto">
  <div class="mx-auto max-w-2xl">
    <div class="text-center">
      <h2 class="text-xl text-gray-800 font-bold sm:text-3xl dark:text-white">
        Post a feedback for {company.name}
      </h2>
    </div>

    <!-- Form -->
    <div class="mt-5 p-4 relative z-10 bg-white border border-gray-300 rounded-xl sm:mt-5 md:px-10 md:py-6 dark:bg-gray-800 dark:border-gray-700">
      <form method="POST" action="?/createFeedback" use:enhance={handleSubmit}>
        <div class="mb-4 sm:mb-8">
          <label for="feedback-post-comment-title-1" class="block mb-2 text-sm font-medium dark:text-white">
            Title
          </label>
          <input type="text" id="hs-feedback-post-comment-title-1" name="title" class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm 
          focus:border-blue-500 focus:ring-blue-500 sm:p-4 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" placeholder="A brief title" />
        </div>
        
        <input type="hidden" name="userId" value={user.id} />
        <input type='hidden' name='companyId' value='{company?.id}' />
        <input type='hidden' name='companySlug' value='{company?.slug}' />

        <div>
          <label for="feedback-post-comment-textarea-1" class="block mb-2 text-sm font-medium dark:text-white">
            Feedback
          </label>
          <div class="mt-1">
            <textarea 
                id="feedback-post-comment-textarea-1" 
                name="content" 
                rows="3" 
                required
                maxlength={contentMaxLength}
                bind:value={formData.content}
                class="py-3 px-4 block w-full border border-gray-300 rounded-md text-sm focus:border-blue-500 focus:ring-blue-500 sm:p-4 
                   dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400" placeholder="Leave your feedback here..."></textarea>
          </div>
            <div class="text-end">
                {#if browser}
                    <p class="text-xs text-gray-400 md:text-sm whitespace-nowrap">
                        {charsRemaining} characters left
                    </p>
                {:else}
                    <p class="text-xs text-gray-400 md:text-sm whitespace-nowrap">Max {contentMaxLength} characters</p>
                {/if}
            </div>
        </div>

        <div class="mt-6 text-center">
            <button type="submit" class="py-3 px-4 w-40 inline-flex justify-center gap-2 rounded-md border border-transparent font-semibold bg-blue-500 text-white hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all dark:focus:ring-offset-gray-800">
                Submit
            </button>
        </div>
      </form>
    </div>
    <!-- End Form -->
  </div>
</div>
<!-- End Feedback Form -->