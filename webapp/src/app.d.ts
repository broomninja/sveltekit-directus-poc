import type { ID, Directus } from '@directus/sdk';
import type { GrowthBook } from '@growthbook/growthbook';

interface UserType {
    id: ID;
    email: string | null;
    first_name?: string | null;
    role?: string | null;
}

// See https://kit.svelte.dev/docs/types#app
// for information about these interfaces
// and what to do when importing types
declare global {
    namespace App {
        interface Error {
            message: string;
            errorId: string;
        }
        interface Locals {
            user: UserType | null;
            directus: Directus | null;
            growthbook: GrowthBook | null;
        }
        // interface PageData {}
        // interface Platform {}
    }
}

// for @poppanator/sveltekit-svg
declare module '*.svg?component' {
    import type { ComponentType, SvelteComponentTyped } from 'svelte';
    import type { SVGAttributes } from 'svelte/elements';
  
    const content: ComponentType<
      SvelteComponentTyped<SVGAttributes<SVGSVGElement>>
    >;
  
    export default content;
}

  
export {};
