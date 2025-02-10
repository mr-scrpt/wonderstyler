import { FC, HTMLAttributes } from "react";

interface Test2 extends HTMLAttributes<HTMLDivElement> {}

export const Test2: FC<Test2> = (props) => {
  const { className } = props;
  return (
    <div className="native">
      <div className="native_inner block">Test2</div>
    </div>
  );
};
