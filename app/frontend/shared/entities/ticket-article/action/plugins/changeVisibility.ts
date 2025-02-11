// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useTicketArticleChangeVisibilityMutation } from '#shared/entities/ticket-article/graphql/mutations/changeVisibility.api.ts'
import type { TicketArticleActionPlugin, TicketArticleAction } from './types.ts'

const changeVisibilityAction = (
  articleId: string,
  targetInternalState: boolean,
) => {
  const errorNotificationMessage = targetInternalState
    ? __('The article could not be set to internal.')
    : __('The article could not be set to public.')

  const mutation = new MutationHandler(
    useTicketArticleChangeVisibilityMutation({
      variables: { articleId, internal: targetInternalState },
    }),
    { errorNotificationMessage },
  )

  return mutation.send()
}

const actionPlugin: TicketArticleActionPlugin = {
  order: 50,

  addActions(ticket, article) {
    const targetInternalState = !article.internal

    const label = targetInternalState
      ? __('Set to internal')
      : __('Set to public')

    const iconName = targetInternalState ? 'lock' : 'lock-open'

    const action: TicketArticleAction = {
      apps: ['mobile'],
      label,
      name: 'changeVisibility',
      icon: { mobile: `mobile-${iconName}`, desktop: `desktop-${iconName}` },
      view: {
        agent: ['change'],
      },
      perform: () => changeVisibilityAction(article.id, targetInternalState),
    }

    return [action]
  },
}

export default actionPlugin
