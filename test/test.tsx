export const NavigationMainLayout: FC<NavigationMainLayoutProps> = (props) => {
  const { className, MenuSlost, listSize } = props;
  return (
    <RowSection
      topology="ROW_CONTAINER"
      className={clsx(sNavigationMainLayout.root, className)}
    >
      <div className={sNavigationMainLayout.inner}>
        <div
          className={clsx(
            sNavigationMainLayout.menu,
            sNavigationMainLayout.menu_top,
          )}
        >
          {MenuSlost}
        </div>
        <ListComponent
          className={clsx("list list_top", sList.list, {
            [sList.list_l]: listSize == "L",
            [slist.list_m]: listSize == "M",
            [sList.list_s]: listSize == "S",
          })}
        >
          <div className={clsx(sList.inner, "list__inner")}>
            <div
              className={clsx(
                sList.item,
                sNavigationMainLayout.menu__item,
                "list__item",
              )}
            >
              <div className={sList.content}>
                <div className={sList.title}>Доставка</div>
              </div>
            </div>
          </div>
        </ListComponent>
      </div>
    </RowSection>
  );
};
