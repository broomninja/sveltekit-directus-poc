<script lang="ts">
    import PersonIcon from '$lib/icons/person.svg?component';

    export let user;
    export let withIcon: boolean = true;

    let name = 'Guest';
    if (!!user) {
        name = `${user.first_name} ${user.last_name ? user.last_name[0] : ''}`;
    }

</script>


{#if withIcon}
    <div class="grid grid-flow-col auto-cols-max">
        <div class="ml-1 pr-1 flex justify-center min-w-[1.8rem] row-span-2">
            <PersonIcon width=22 />
        </div>
        <div class="ml-1 text-md text-gray-800 dark:text-gray-400">
            {name}
        </div>
    </div>
{:else}
    <span>
        {name}
    </span>
{/if}
