<script lang="ts">
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';
    import { useTooltip } from '@untemps/svelte-use-tooltip';
    import { fade } from 'svelte/transition';
    import MessageSquareIcon from '$lib/icons/messageSquare.svg?component';
    import UpvoteIcon from '$lib/icons/upvote.svg?component';
    
    export let companySlug;
    export let feedback;
</script>

{#if !!feedback && !!companySlug}
    <!-- Tooltip Content -->
    <template id="tooltip-template-{feedback.id}">
        <div class="grid grid-rows-2 h-full justify-between">
            <div class="p-2 line-clamp-2 font-semibold text-sm">
                {feedback.title}
            </div>
            <div class="px-2 mb-1 line-clamp-2 text-md">
                {@html feedback.content}
            </div>
        </div>
    </template>
    <!-- Tooltip Content End -->
    <div class="text-left"
        use:useTooltip={{
            position: 'top',
            contentSelector: `#tooltip-template-${feedback.id}`,
            containerClassName: `tooltip-feedback tooltip-feedback--top`,
            animated: true,
            enterDelay: 20,
            leaveDelay: 250,
            offset: 10,
        }}  
    >
        <a class="min-w-[14rem] group flex flex-col bg-white border shadow-sm rounded-xl hover:shadow-md dark:bg-slate-900 dark:border-gray-800" 
            href="/company/{companySlug}/feedback/{feedback.id}">
            <div class="p-4 md:p-4 min-w-[14rem]">
                <div class="flex justify-between items-stretch bg-white">
                    <div class="bg-white">
                        <div class="h-[3rem] w-[9rem] group-hover:text-blue-600 line-clamp-2 font-semibold text-gray-800 dark:group-hover:text-gray-400 dark:text-gray-200">
                        {feedback.title}
                        </div>
                        <div class="md:mt-2 text-sm text-gray-500 pb-0">
                            <DisplayTime prefix={'created'} datetime={feedback.date_created} /> 
                            <br />
                            by <DisplayName withIcon={false} user={feedback.author} />
                        </div>
                    </div>
                    <div class="pl-3 bg-white flex flex-col justify-between">
                        <div class="bg-white flex text-md justify-between align-center">
                            <UpvoteIcon />
                            <!-- // TODO: currently only handles up to 3 digits before overflowing -->
                            {feedback.voter_count}
                        </div>
                        <div class="flex items-end gap-x-1">
                            {#if !!feedback.comment_count}
                            <MessageSquareIcon width=20 />
                            {feedback.comment_count}
                            {/if}    
                        </div>
                    </div>
                </div>
            </div>
        </a>
    </div>
{/if}

<style>

    :global(.tooltip-feedback) {
        position: absolute;
        z-index: 9999;
        width: 250px;
        height: 130px;
        background-color: rgb(243 244 246);
        color: black;
        text-align: left;
        border-radius: 6px;
        padding: 0.5rem;
        border: 1px solid rgb(156 163 175);

    }

    :global(.tooltip-feedback::after) {
        content: '';
        position: absolute;
        margin-left: -5px;
        border-width: 5px;
        border-style: solid;
    }

    :global(.tooltip-feedback--top::before,
    .tooltip-feedback--top::after) {
    top: 100%;
    left: 50%;
    transform: translate(-50%);
    margin-bottom: 15px;

    }

    :global(.tooltip-feedback--top::after) {
    margin-bottom: 8px;
    border-left: 5px solid transparent;
    border-right: 5px solid transparent;
    border-top: 7px solid rgb(156 163 175);
    }

</style>