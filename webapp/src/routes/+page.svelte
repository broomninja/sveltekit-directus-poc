<script lang="ts">
    import type { PageData } from './$types';
    import DisplayName from '$lib/components/DisplayName.svelte';
    import DisplayTime from '$lib/components/DisplayTime.svelte';
    import CardFeedbackSmall from '$lib/components/CardFeedbackSmall.svelte';

    export let data: PageData;

</script>


<!-- ========== MAIN CONTENT ========== -->

<!-- Nav -->
<nav class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
  <div class="relative flex flex-row justify-between items-center mt-4 gap-x-8 py-4 sm:py-0 dark:border-slate-700">
    <div class="flex items-center w-full sm:w-[auto]">
      <span class="font-semibold whitespace-nowrap text-gray-800 border-r border-r-white/[.7] sm:border-transparent pr-4 mr-4 sm:py-3.5 dark:text-white">
        Most Active Companies
      </span>

      <div class="w-full sm:hidden">
        <button type="button" class="hs-collapse-toggle group w-full inline-flex justify-between items-center gap-2 rounded-md font-medium text-gray-600 border border-gray-200 align-middle py-1.5 px-2 hover:text-gray-800 focus:outline-none focus:ring-2 focus:ring-white/[.5] transition" data-hs-collapse="#secondary-nav-toggle" aria-controls="secondary-nav-toggle" aria-label="Toggle navigation">
          Top 10
          <svg class="hs-dropdown-open:rotate-180 w-2.5 h-2.5 text-gray-600 transition group-hover:text-gray-800" width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M2 5L8.16086 10.6869C8.35239 10.8637 8.64761 10.8637 8.83914 10.6869L15 5" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
          </svg>
        </button>
      </div>
    </div>

    <div id="secondary-nav-toggle" class="hs-collapse hidden overflow-hidden transition-all duration-300 absolute top-16 left-0 w-4/5 
      rounded-md bg-white sm:block sm:static sm:top-0 sm:w-4/5 sm:max-h-full sm:bg-transparent sm:overflow-visible">
      <div class="flex flex-col py-2 sm:flex-row sm:justify-start sm:gap-y-0 sm:gap-x-6 sm:py-0">
        {#each data.companies as company}
        <a href="#{company.slug}" class="group flex min-w-[9rem] items-center rounded-lg px-1 py-2 text-gray-700 bg-gray-100 hover:bg-gray-300 hover:text-gray-700">
          <div class="flex gap-2">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 12h16.5m-16.5 3.75h16.5M3.75 19.5h16.5M5.625 4.5h12.75a1.875 1.875 0 010 3.75H5.625a1.875 1.875 0 010-3.75z" />
            </svg>
            <span class="text-sm font-medium">
              {company?.name}
            </span>
          </div>
          <div class="flex ml-auto pl-1">
            <span class="shrink-0 rounded-full bg-white py-0.5 px-3 text-xs text-gray-600 group-hover:bg-white group-hover:text-gray-700"> 
              {company?.feedback_count} 
            </span>
          </div>
        </a>
        {/each}
      </div>
    </div>

  </div>
</nav>
<!-- End Nav -->

    <!-- Content -->
    <div class="w-full px-4 sm:px-6 md:px-8">
      <div class="max-w-3xl mx-auto lg:max-w-5xl xl:max-w-none py-0 lg:mx-15 xl:mx-20">

        <!-- Content -->
        <div class="mt-12">
          <div id="scrollspy" class="space-y-10 md:space-y-10">
            {#each data.companies as company}
              <div id="{company.slug}" class="scroll-mt-14 min-h-[16rem]">
                <h2 class="text-lg font-semibold text-gray-800 dark:text-white">
                  <a href="/company/{company.slug}">Most popular feedbacks for {company.name}</a> 
                </h2>
                <!-- Card Section -->
                <div class="max-w-[135rem] px-4 pt-8 sm:px-6 lg:px-6 lg:pt-8 mx-auto">
                    <!-- Grid -->
                    <div class="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6">
                        <!-- Card -->
                        {#each company?.feedback as feedback}
                        <CardFeedbackSmall companySlug={company.slug} {feedback} />
                        {:else}
                        <div>No feedbacks found</div>
                        {/each}
                        <!-- End Card -->
                    </div>
                    <div class="mt-5 text-center text-lg font-semibold text-gray-800 dark:text-white">
                        {#if company?.feedback_count > data.feedbackLimitPerCompany}
                        <a href="/company/{company.slug}" class="hover:text-blue-600">more feedbacks...</a> 
                        {/if}
                    </div>
                    <!-- End Grid -->
                </div>
                <!-- End Card Section -->

              </div>
            {:else}
              <div>No companies found</div>
            {/each}
          </div>
        </div>
        <!-- End Content -->

      </div>
    </div>
    <!-- End Content -->
  
<!-- ========== END MAIN CONTENT ========== -->

<!-- Debug data
Company = {JSON.stringify(company, null, 2)}
-->

<!-- Debug data
Feedback = {JSON.stringify(feedback, null, 2)}
-->