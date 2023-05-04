<script lang="ts">
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';
    
    export let feedback;
</script>

{#if !!feedback}
    <div class="text-left mb-2">
        <a class="min-w-[14rem] group flex flex-col bg-white border shadow-sm rounded-xl hover:shadow-md dark:bg-slate-900 dark:border-gray-800" 
            href="/company/{feedback['company_id.slug']}/feedback/{feedback.id}">
            <div class="p-4 md:p-4 min-w-[14rem]">
                <div class="grid h-full">
                    <div class="mb-1 line-clamp-1 font-semibold text-sm">
                        Company: {feedback['company_id.name']}
                    </div>
                    <div class="mb-1 line-clamp-2 font-semibold text-sm">
                        Title: {feedback.title}
                    </div>
                    <div class="mb-1 line-clamp-2 text-sm">
                        {@html feedback.content}
                    </div>
                    <div class="md:mt-2 text-sm text-gray-500 text-xs whitespace-nowrap">
                        <DisplayTime prefix={'created'} datetime={feedback.date_created} /> 
                        
                        by {feedback['author_id.first_name']} {feedback['author_id.last_name'][0]}
                    </div>
                </div>
            </div>
        </a>
    </div>
{/if}
