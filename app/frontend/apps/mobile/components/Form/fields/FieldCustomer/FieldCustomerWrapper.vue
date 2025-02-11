<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->
<script setup lang="ts">
import { markRaw, defineAsyncComponent, nextTick } from 'vue'
import type { ObjectLike } from '#shared/types/utils.ts'
import { useUserCreate } from '#mobile/entities/user/composables/useUserCreate.ts'
import type { FormFieldContext } from '#shared/components/Form/types/field.ts'
import type { AutoCompleteProps } from '#shared/components/Form/fields/FieldAutocomplete/types.ts'
import type { AutoCompleteCustomerOption } from '#shared/components/Form/fields/FieldCustomer/types.ts'
import type { SelectValue } from '#shared/components/CommonSelect/types.ts'
import { AutocompleteSearchUserDocument } from '#shared/components/Form/fields/FieldCustomer/graphql/queries/autocompleteSearch/user.api.ts'
import { closeDialog } from '#shared/composables/useDialog.ts'
import type { User } from '#shared/graphql/types.ts'
import FieldCustomerOptionIcon from './FieldCustomerOptionIcon.vue'

const FieldAutoCompleteInput = defineAsyncComponent(
  () =>
    import(
      '#mobile/components/Form/fields/FieldAutoComplete/FieldAutoCompleteInput.vue'
    ),
)

interface Props {
  context: FormFieldContext<
    AutoCompleteProps & {
      options?: AutoCompleteCustomerOption[]
    }
  >
}

const props = defineProps<Props>()

const buildEntityOption = (entity: User) => {
  return {
    value: entity.internalId,
    label: entity.fullname || entity.phone || entity.login,
    heading: entity.organization?.name,
    user: entity,
  }
}

const { openCreateUserDialog } = useUserCreate({
  async onUserCreated(user) {
    const { props: nodeProps } = props.context.node
    // If the user is not in options, add it
    if (
      !nodeProps.options?.some(
        (v: AutoCompleteCustomerOption) => v.value === user.internalId,
      )
    ) {
      nodeProps.options = [
        ...(nodeProps.options || []),
        buildEntityOption(user),
      ]
    }
    await nextTick()
    props.context.node.input(user.internalId, false)
    closeDialog(`field-auto-complete-${props.context.id}`)
  },
})

Object.assign(props.context, {
  optionIconComponent: markRaw(FieldCustomerOptionIcon),
  initialOptionBuilder: (
    initialEntityObject: ObjectLike,
    value: SelectValue,
    context: Props['context'],
  ) => {
    if (!context.belongsToObjectField || !initialEntityObject) return null

    const belongsToObject = initialEntityObject[context.belongsToObjectField]

    if (!belongsToObject) return null

    return buildEntityOption(belongsToObject)
  },

  actionIcon: 'mobile-new-customer',
  actionLabel: __('Create new customer'),

  gqlQuery: AutocompleteSearchUserDocument,

  onActionClick: openCreateUserDialog,
})
</script>

<template>
  <FieldAutoCompleteInput :context="context" v-bind="$attrs" />
</template>
